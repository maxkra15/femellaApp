import SwiftUI
import UserNotifications

@main
struct femellaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appVM = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appVM)
                .preferredColorScheme(.light)
                .onReceive(NotificationCenter.default.publisher(for: .deviceTokenReceived)) { notification in
                    if let token = notification.object as? String {
                        UserDefaults.standard.set(token, forKey: "apnsDeviceToken")
                        Task {
                            try? await SupabaseService.shared.upsertDeviceToken(token)
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                }
        }
    }
}

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Increase URLCache capacity to store images effectively (50MB memory, 500MB disk)
        let cache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: "femella_image_cache")
        URLCache.shared = cache
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📱 APNs device token: \(token)")
        NotificationCenter.default.post(name: .deviceTokenReceived, object: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for push: \(error.localizedDescription)")
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Could deep-link to specific content here in the future
        print("📱 Notification tapped: \(response.notification.request.content.title)")
    }
}

extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        Group {
            switch appVM.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                LoginView()
            case .profileIncomplete:
                ProfileCompletionView()
            case .paywalled:
                PaywallView()
            case .authenticated:
                ContentView()
            }
        }
        .animation(.snappy, value: appVM.authState)
        .task {
            await appVM.restoreSession()
        }
        .onChange(of: appVM.authState) { _, newState in
            if newState == .authenticated {
                requestPushPermission()
            }
        }
    }

    private func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

struct LoadingView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            FemColor.ivory.ignoresSafeArea()

            // Decorative circles
            CirclePattern(size: 320, opacity: 0.06)
                .offset(x: 60, y: -80)

            VStack(spacing: 20) {
                FemLogo(size: 80, style: .pink)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Text("femella")
                    .font(FemFont.display(32))
                    .foregroundStyle(FemColor.darkBlue)
            }
        }
        .onAppear { pulse = true }
    }
}
