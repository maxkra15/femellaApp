import SwiftUI

@Observable
@MainActor
class EventsViewModel {
    var events: [Event] = []
    var registrations: [EventRegistration] = []
    var isLoading: Bool = false
    var selectedCategory: EventCategory?
    var searchText: String = ""

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
        let status: String = event.isFull ? "waitlisted" : "registered"
        do {
            let reg = try await service.registerForEvent(
                eventId: event.id,
                userId: userId,
                status: status
            )
            registrations.append(reg)
            // Update local count
            if let idx = events.firstIndex(where: { $0.id == event.id }) {
                let updated = events[idx]
                let newEvent = Event(
                    id: updated.id, hubId: updated.hubId, category: updated.category,
                    title: updated.title, description: updated.description,
                    heroImageURL: updated.heroImageURL, locationName: updated.locationName,
                    address: updated.address, latitude: updated.latitude, longitude: updated.longitude,
                    startsAt: updated.startsAt, endsAt: updated.endsAt,
                    capacity: updated.capacity,
                    registeredCount: event.isFull ? updated.registeredCount : updated.registeredCount + 1,
                    waitlistCount: event.isFull ? updated.waitlistCount + 1 : updated.waitlistCount,
                    status: updated.status, registrationOpensAt: updated.registrationOpensAt,
                    registrationClosesAt: updated.registrationClosesAt,
                    priceAmount: updated.priceAmount, currency: updated.currency,
                    isNonDeregisterable: updated.isNonDeregisterable,
                    deregistrationDeadlineHoursOverride: updated.deregistrationDeadlineHoursOverride,
                    noShowFeeAmountOverride: updated.noShowFeeAmountOverride,
                    hostName: updated.hostName, attendeeAvatarURLs: updated.attendeeAvatarURLs
                )
                events[idx] = newEvent
            }
        } catch {
            print("Register error: \(error)")
        }
    }

    func deregisterFromEvent(_ event: Event) async {
        if let reg = registrations.first(where: { $0.eventId == event.id && $0.status != .canceled }) {
            do {
                try await service.deregisterFromEvent(registrationId: reg.id)
                if let idx = registrations.firstIndex(where: { $0.id == reg.id }) {
                    registrations[idx] = EventRegistration(
                        id: reg.id, eventId: reg.eventId, userId: reg.userId,
                        status: .canceled, registeredAt: reg.registeredAt,
                        canceledAt: Date(), position: reg.position
                    )
                }
            } catch {
                print("Deregister error: \(error)")
            }
        }
    }
}
