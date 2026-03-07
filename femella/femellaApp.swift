import SwiftUI
import UserNotifications
import UIKit

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
                        SupabaseService.shared.cacheDeviceToken(token)
                        syncDeviceToken(token, source: "apns callback")
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        refreshPushRegistrationIfNeeded(promptIfNeeded: shouldMaintainPushRegistration(for: appVM.authState))
                        if shouldMaintainPushRegistration(for: appVM.authState) {
                            syncCachedPushToken(source: "app became active")
                        }
                    }
                }
        }
    }

    private func syncDeviceToken(_ token: String, source: String) {
        Task {
            do {
                try await SupabaseService.shared.upsertDeviceToken(token)
                print("📱 Synced APNs token from \(source)")
            } catch {
                print("❌ Failed to sync APNs token from \(source): \(error.localizedDescription)")
            }
        }
    }

}

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        configureTabBarAppearance()

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

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor(FemColor.pureWhite).withAlphaComponent(0.72)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(FemColor.richBlack).withAlphaComponent(0.9)
        normal.titleTextAttributes = [.foregroundColor: UIColor(FemColor.richBlack).withAlphaComponent(0.9)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(FemColor.pink)
        selected.titleTextAttributes = [.foregroundColor: UIColor(FemColor.pink)]

        let badgeColor = UIColor(FemColor.orangeRed)
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = badgeColor
        appearance.stackedLayoutAppearance.selected.badgeBackgroundColor = badgeColor

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().unselectedItemTintColor = UIColor(FemColor.richBlack).withAlphaComponent(0.9)
    }
}

extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
}

private func syncCachedPushToken(source: String, successPrefix: String = "📱 Synced cached APNs token from") {
    Task {
        do {
            let synced = try await SupabaseService.shared.syncCachedDeviceToken()
            if synced {
                print("\(successPrefix) \(source)")
            }
        } catch {
            print("❌ Failed to sync cached APNs token from \(source): \(error.localizedDescription)")
        }
    }
}

private func refreshPushRegistrationIfNeeded(promptIfNeeded: Bool = true) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        case .notDetermined:
            guard promptIfNeeded else { return }
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
        case .denied:
            print("🔕 Push notifications are denied in system settings")
        @unknown default:
            break
        }
    }
}

private func shouldMaintainPushRegistration(for authState: AuthState) -> Bool {
    switch authState {
    case .authenticated, .profileIncomplete, .paywalled:
        return SupabaseService.shared.currentUserId != nil
    case .loading, .unauthenticated:
        return false
    }
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
            if shouldMaintainPushRegistration(for: newState) {
                refreshPushRegistrationIfNeeded(promptIfNeeded: true)
                syncCachedPushToken(source: "authentication", successPrefix: "📱 Re-synced cached APNs token after")
            }
        }
        .dismissKeyboardOnTap()
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
