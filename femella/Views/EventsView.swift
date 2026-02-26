import SwiftUI

struct EventsView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var eventsVM: EventsViewModel
    @State private var searchText: String = ""
    @Namespace private var eventTransition

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FemSpacing.lg) {
                    categoryChips

                    if eventsVM.isLoading {
                        loadingSkeleton
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
            .femAmbientBackground()
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
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event, eventsVM: eventsVM, transitionNamespace: eventTransition)
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

    private var loadingSkeleton: some View {
        VStack(spacing: FemSpacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                EventCardSkeleton()
            }
        }
        .padding(.top, FemSpacing.sm)
    }

    private var eventSections: some View {
        VStack(spacing: FemSpacing.xl) {
            if !eventsVM.thisWeekEvents.isEmpty {
                EventSection(title: "This Week", events: eventsVM.thisWeekEvents, eventsVM: eventsVM, transitionNamespace: eventTransition)
            }
            if !eventsVM.nextWeekEvents.isEmpty {
                EventSection(title: "Next Week", events: eventsVM.nextWeekEvents, eventsVM: eventsVM, transitionNamespace: eventTransition)
            }
            if !eventsVM.laterEvents.isEmpty {
                EventSection(title: "Later", events: eventsVM.laterEvents, eventsVM: eventsVM, transitionNamespace: eventTransition)
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
            .foregroundStyle(FemColor.darkBlue)
        }
    }
}

private struct EventSection: View {
    let title: String
    let events: [Event]
    let eventsVM: EventsViewModel
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: FemSpacing.md) {
            Text(title)
                .font(FemFont.title(20))
                .foregroundStyle(FemColor.darkBlue)

            ForEach(events) { event in
                NavigationLink(value: event) {
                    EventCard(
                        event: event,
                        registration: eventsVM.registrationFor(eventId: event.id),
                        transitionNamespace: transitionNamespace
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    let registration: EventRegistration?
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(FemColor.ivory)
                .frame(height: 160)
                .overlay {
                    CachedAsyncImage(url: event.heroImageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            SkeletonBlock(height: 160, cornerRadius: 0)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Text(event.category.rawValue)
                            .font(FemFont.caption(weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor(event.category))
                            .clipShape(Capsule())

                        if !event.isFree {
                            Text(event.priceDisplay)
                                .font(FemFont.caption(weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(FemFont.title(20))
                    .foregroundStyle(FemColor.darkBlue)
                    .lineLimit(2)

                HStack(spacing: FemSpacing.md) {
                    Label(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()), systemImage: "calendar")
                    Label(event.startsAt.formatted(.dateTime.hour().minute()), systemImage: "clock")
                }
                .font(FemFont.caption())
                .foregroundStyle(FemColor.darkBlue.opacity(0.5))

                HStack {
                    Label(event.locationName, systemImage: "mappin")
                        .font(FemFont.caption())
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        .lineLimit(1)

                    Spacer()

                    if let reg = registration {
                        StatusBadge(
                            text: reg.status == .waitlisted ? "Waitlisted" : "Registered",
                            color: reg.status == .waitlisted ? FemColor.orangeRed : FemColor.green,
                            icon: reg.status == .waitlisted ? "list.bullet.clipboard.fill" : "checkmark.seal.fill"
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(event.registeredCount)/\(event.capacity)")
                        }
                        .font(FemFont.caption())
                        .foregroundStyle(event.isFull ? FemColor.orangeRed : FemColor.darkBlue.opacity(0.4))
                    }
                }
            }
            .padding(FemSpacing.lg)
        }
        .femCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(FemColor.darkBlue.opacity(0.06), lineWidth: 1)
        )
        .matchedTransitionSource(id: event.id, in: transitionNamespace)
    }

    private func categoryColor(_ cat: EventCategory) -> Color {
        switch cat {
        case .connect: FemColor.pink
        case .learn: FemColor.lightBlue
        case .grow: FemColor.green
        }
    }
}

private struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(height: 160, cornerRadius: 0)
            VStack(alignment: .leading, spacing: 10) {
                SkeletonBlock(width: 120, height: 14, cornerRadius: 7)
                SkeletonBlock(height: 22, cornerRadius: 8)
                SkeletonBlock(width: 200, height: 12, cornerRadius: 6)
                SkeletonBlock(width: 160, height: 12, cornerRadius: 6)
            }
            .padding(FemSpacing.lg)
        }
        .background(Color.white.opacity(0.72))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
        )
    }
}
