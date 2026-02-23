import SwiftUI

struct MyEventsView: View {
    @Environment(AppViewModel.self) private var appVM
    let eventsVM: EventsViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, FemSpacing.lg)
                .padding(.vertical, FemSpacing.sm)

                ScrollView {
                    LazyVStack(spacing: FemSpacing.md) {
                        let events = selectedTab == 0 ? eventsVM.myUpcomingEvents : eventsVM.myPastEvents

                        if events.isEmpty {
                            ContentUnavailableView(
                                selectedTab == 0 ? "No Upcoming Events" : "No Past Events",
                                systemImage: selectedTab == 0 ? "calendar.badge.plus" : "clock",
                                description: Text(selectedTab == 0 ? "Browse events and register to see them here." : "Your attended events will appear here.")
                            )
                            .frame(minHeight: 300)
                        } else {
                            ForEach(events) { event in
                                NavigationLink(value: event) {
                                    MyEventCard(event: event, registration: eventsVM.registrationFor(eventId: event.id))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, FemSpacing.lg)
                    .padding(.bottom, FemSpacing.xxl)
                }
                .navigationDestination(for: Event.self) { event in
                    EventDetailView(event: event, eventsVM: eventsVM)
                }
            }
            .background(FemColor.ivory.ignoresSafeArea())
            .navigationTitle("My Events")
        }
    }
}

private struct MyEventCard: View {
    let event: Event
    let registration: EventRegistration?

    var body: some View {
        HStack(spacing: FemSpacing.lg) {
            Color(FemColor.ivory)
                .frame(width: 80, height: 80)
                .overlay {
                    AsyncImage(url: event.heroImageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FemColor.darkBlue)
                    .lineLimit(2)

                Text(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.5))

                HStack(spacing: 8) {
                    statusBadge

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                        Text("\(event.registeredCount)/\(event.capacity)")
                    }
                    .font(.caption2)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                }
            }
        }
        .padding(FemSpacing.md)
        .femCard()
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let reg = registration {
            switch reg.status {
            case .registered:
                StatusBadge(text: "Registered", color: FemColor.green)
            case .waitlisted:
                StatusBadge(text: "Waitlisted", color: FemColor.orangeRed)
            case .attended:
                StatusBadge(text: "Participated", color: FemColor.green)
            case .noShow:
                StatusBadge(text: "No Show", color: FemColor.orangeRed)
            case .canceled:
                StatusBadge(text: "Cancelled", color: .secondary)
            }
        }
    }
}
