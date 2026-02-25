import SwiftUI

@Observable
@MainActor
class EventsViewModel {
    var events: [Event] = []
    var registrations: [EventRegistration] = []
    var isLoading: Bool = false
    var selectedCategory: EventCategory?
    var searchText: String = ""
    private var inFlightEventMutations: Set<String> = []

    private let service = SupabaseService.shared

    var filteredEvents: [Event] {
        var result = events.filter { $0.status == .published || $0.status == .completed }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.hostName.localizedCaseInsensitiveContains(searchText) ||
                $0.locationName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.startsAt < $1.startsAt }
    }

    var upcomingEvents: [Event] {
        filteredEvents.filter { !$0.isPast }
    }

    var pastEvents: [Event] {
        filteredEvents.filter { $0.isPast }
    }

    var thisWeekEvents: [Event] {
        let cal = Calendar.current
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: Date())!
        return upcomingEvents.filter { $0.startsAt <= endOfWeek }
    }

    var nextWeekEvents: [Event] {
        let cal = Calendar.current
        let startOfNext = cal.date(byAdding: .day, value: 7, to: Date())!
        let endOfNext = cal.date(byAdding: .day, value: 14, to: Date())!
        return upcomingEvents.filter { $0.startsAt > startOfNext && $0.startsAt <= endOfNext }
    }

    var laterEvents: [Event] {
        let cal = Calendar.current
        let endOfNext = cal.date(byAdding: .day, value: 14, to: Date())!
        return upcomingEvents.filter { $0.startsAt > endOfNext }
    }

    var myUpcomingEvents: [Event] {
        let registeredIds = Set(registrations.filter { $0.status == .registered || $0.status == .waitlisted }.map(\.eventId))
        return events.filter { registeredIds.contains($0.id) && !$0.isPast }.sorted { $0.startsAt < $1.startsAt }
    }

    var myPastEvents: [Event] {
        let myIds = Set(registrations.map(\.eventId))
        return events.filter { myIds.contains($0.id) && $0.isPast }.sorted { $0.startsAt > $1.startsAt }
    }

    func registrationFor(eventId: String) -> EventRegistration? {
        registrations.first { $0.eventId == eventId && $0.status != .canceled }
    }

    func loadEvents(hubId: String) async {
        isLoading = true
        do {
            events = try await service.fetchEvents(hubId: hubId)
            if let userId = service.currentUserId {
                registrations = try await service.fetchRegistrations(userId: userId)
            }
        } catch {
            print("Failed to load events: \(error)")
        }
        isLoading = false
    }

    func registerForEvent(_ event: Event) async {
        guard let userId = service.currentUserId else { return }
        guard registrationFor(eventId: event.id) == nil else { return }
        guard !inFlightEventMutations.contains(event.id) else { return }
        inFlightEventMutations.insert(event.id)
        defer { inFlightEventMutations.remove(event.id) }

        let latestEvent = events.first(where: { $0.id == event.id }) ?? event
        let status: String = latestEvent.isFull ? "waitlisted" : "registered"
        do {
            let reg = try await service.registerForEvent(
                eventId: latestEvent.id,
                userId: userId,
                status: status
            )
            registrations.append(reg)
            await refreshEventState(hubId: latestEvent.hubId, userId: userId)
        } catch {
            print("Register error: \(error)")
        }
    }

    func deregisterFromEvent(_ event: Event) async {
        guard let userId = service.currentUserId else { return }
        guard !inFlightEventMutations.contains(event.id) else { return }
        guard let reg = registrations.first(where: { $0.eventId == event.id && $0.status != .canceled }) else { return }

        inFlightEventMutations.insert(event.id)
        defer { inFlightEventMutations.remove(event.id) }

        do {
            try await service.deregisterFromEvent(registrationId: reg.id)
            if let idx = registrations.firstIndex(where: { $0.id == reg.id }) {
                registrations[idx] = EventRegistration(
                    id: reg.id, eventId: reg.eventId, userId: reg.userId,
                    status: .canceled, registeredAt: reg.registeredAt,
                    canceledAt: Date(), position: reg.position
                )
            }
            await refreshEventState(hubId: event.hubId, userId: userId)
        } catch {
            print("Deregister error: \(error)")
        }
    }

    private func refreshEventState(hubId: String, userId: String) async {
        do {
            events = try await service.fetchEvents(hubId: hubId)
            registrations = try await service.fetchRegistrations(userId: userId)
        } catch {
            print("Failed to refresh event state: \(error)")
        }
    }
}
