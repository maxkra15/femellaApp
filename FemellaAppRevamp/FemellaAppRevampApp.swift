import SwiftUI

@main
struct FemellaAppRevampApp: App {
    @State private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appVM)
        }
    }
}

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
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(FemColor.accentPink)
            Text("femella")
                .font(.title2.bold())
                .foregroundStyle(FemColor.navy)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FemColor.blush.ignoresSafeArea())
    }
}
