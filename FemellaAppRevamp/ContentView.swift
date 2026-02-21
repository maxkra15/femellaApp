import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var eventsVM = EventsViewModel()
    @State private var notificationsVM = NotificationsViewModel()
    @State private var surveysVM = SurveysViewModel()
    @State private var selectedTab: AppTab = .events

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Events", systemImage: "calendar", value: .events) {
                EventsView(eventsVM: eventsVM)
            }

            Tab("My Events", systemImage: "ticket", value: .myEvents) {
                MyEventsView(eventsVM: eventsVM)
            }

            Tab("Notifications", systemImage: "bell", value: .notifications) {
                NotificationsView(notificationsVM: notificationsVM)
            }
            .badge(notificationsVM.unreadCount)

            Tab("Surveys", systemImage: "doc.text", value: .surveys) {
                SurveysView(surveysVM: surveysVM)
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
        }
        .tint(FemColor.accentPink)
    }
}

nonisolated enum AppTab: Hashable, Sendable {
    case events
    case myEvents
    case notifications
    case surveys
    case profile
}
