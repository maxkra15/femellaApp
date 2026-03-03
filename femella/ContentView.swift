import SwiftUI

struct ContentView: View {
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
                    Image(systemName: "newspaper")
                    Text("My Events")
                }
                .tag(1)

            InteractView(surveysVM: surveysVM)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Interact")
                }
                .tag(2)

            NotificationsView(notificationsVM: notificationsVM)
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .badge(notificationsVM.unreadCount)
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(FemColor.pink)
    }
}
