import SwiftUI

struct EventsView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var eventsVM: EventsViewModel
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.lg) {
                    categoryChips

                    if eventsVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if eventsVM.upcomingEvents.isEmpty {
                        ContentUnavailableView("No Events", systemImage: "calendar.badge.exclamationmark", description: Text("No upcoming events match your filters."))
                            .frame(minHeight: 300)
                    } else {
                        eventSections
                    }
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .background(FemColor.blush.ignoresSafeArea())
            .navigationTitle("Events")
            .searchable(text: $searchText, prompt: "Search events...")
            .onChange(of: searchText) { _, newValue in
                eventsVM.searchText = newValue
            }
            .task {
                await eventsVM.loadEvents(hubId: appVM.selectedHubId)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    hubPicker
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: eventsVM.selectedCategory == nil) {
                    eventsVM.selectedCategory = nil
                }
                ForEach(EventCategory.allCases, id: \.self) { cat in
                    CategoryChip(title: cat.rawValue, isSelected: eventsVM.selectedCategory == cat) {
                        eventsVM.selectedCategory = cat
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var eventSections: some View {
        VStack(spacing: FemSpacing.xl) {
            if !eventsVM.thisWeekEvents.isEmpty {
                EventSection(title: "This Week", events: eventsVM.thisWeekEvents, eventsVM: eventsVM)
            }
            if !eventsVM.nextWeekEvents.isEmpty {
                EventSection(title: "Next Week", events: eventsVM.nextWeekEvents, eventsVM: eventsVM)
            }
            if !eventsVM.laterEvents.isEmpty {
                EventSection(title: "Later", events: eventsVM.laterEvents, eventsVM: eventsVM)
            }
        }
    }

    private var hubPicker: some View {
        Menu {
            ForEach(appVM.hubs.filter(\.isActive)) { hub in
                Button {
                    appVM.selectedHubId = hub.id
                    Task { await eventsVM.loadEvents(hubId: hub.id) }
                } label: {
                    Label(hub.name, systemImage: appVM.selectedHubId == hub.id ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                Text(appVM.selectedHub?.name ?? "Hub")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(FemColor.navy)
        }
    }
}

private struct EventSection: View {
    let title: String
    let events: [Event]
    let eventsVM: EventsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(FemColor.navy)

            ForEach(events) { event in
                NavigationLink(value: event) {
                    EventCard(event: event, registration: eventsVM.registrationFor(eventId: event.id))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event, eventsVM: eventsVM)
        }
    }
}

struct EventCard: View {
    let event: Event
    let registration: EventRegistration?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(.secondarySystemBackground)
                .frame(height: 160)
                .overlay {
                    AsyncImage(url: event.heroImageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Text(event.category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor(event.category))
                            .clipShape(Capsule())

                        if !event.isFree {
                            Text(event.priceDisplay)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(FemColor.navy)
                    .lineLimit(2)

                HStack(spacing: FemSpacing.md) {
                    Label(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()), systemImage: "calendar")
                    Label(event.startsAt.formatted(.dateTime.hour().minute()), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Label(event.locationName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if let reg = registration {
                        StatusBadge(
                            text: reg.status == .waitlisted ? "Waitlisted" : "Registered",
                            color: reg.status == .waitlisted ? .orange : FemColor.success
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(event.registeredCount)/\(event.capacity)")
                        }
                        .font(.caption)
                        .foregroundStyle(event.isFull ? FemColor.danger : .secondary)
                    }
                }
            }
            .padding(FemSpacing.lg)
        }
        .femCard()
    }

    private func categoryColor(_ cat: EventCategory) -> Color {
        switch cat {
        case .connect: FemColor.accentPink
        case .learn: FemColor.ctaBlue
        case .grow: FemColor.success
        }
    }
}
