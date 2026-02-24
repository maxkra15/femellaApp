import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var eventsVM = EventsViewModel()
    @State private var notificationsVM = NotificationsViewModel()
    @State private var surveysVM = SurveysViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EventsView(eventsVM: eventsVM)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(0)

            MyEventsView(eventsVM: eventsVM)
                .tabItem {
                    Image(systemName: "heart.circle")
                    Text("My Events")
                }
                .tag(1)

            NotificationsView(notificationsVM: notificationsVM)
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .badge(notificationsVM.unreadCount)
                .tag(2)

            InteractView(surveysVM: surveysVM)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Interact")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(FemColor.darkBlue)
    }
}
