import SwiftUI

nonisolated enum AuthState: Sendable, Equatable {
    case loading
    case unauthenticated
    case profileIncomplete
    case paywalled
    case authenticated
}

@Observable
@MainActor
class AppViewModel {
    var authState: AuthState = .unauthenticated
    var currentUser: UserProfile?
    var membership: Membership?
    var selectedHubId: String = "hub-zurich"
    var hubs: [Hub] = MockDataService.hubs

    var selectedHub: Hub? {
        hubs.first { $0.id == selectedHubId }
    }

    var isMembershipActive: Bool {
        membership?.isActive ?? false
    }

    func signIn(email: String, password: String) async {
        authState = .loading
        try? await Task.sleep(for: .seconds(1))
        currentUser = MockDataService.sampleUser
        membership = MockDataService.sampleMembership
        authState = .authenticated
    }

    func signUp(email: String, password: String) async {
        authState = .loading
        try? await Task.sleep(for: .seconds(1))
        currentUser = UserProfile(
            id: UUID().uuidString,
            firstName: "",
            lastName: "",
            email: email,
            phone: "",
            university: "",
            degree: "",
            company: "",
            jobTitle: "",
            homeHubId: "",
            avatarURL: nil,
            showProfileToMembers: true
        )
        authState = .profileIncomplete
    }

    func completeProfile(_ profile: UserProfile) async {
        authState = .loading
        try? await Task.sleep(for: .seconds(0.5))
        currentUser = profile
        selectedHubId = profile.homeHubId
        authState = .paywalled
    }

    func activateMembership() async {
        try? await Task.sleep(for: .seconds(1))
        membership = Membership(
            id: UUID().uuidString,
            userId: currentUser?.id ?? "",
            hubId: selectedHubId,
            status: .active,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            source: .stripe
        )
        authState = .authenticated
    }

    func redeemCode(_ code: String) async -> Bool {
        try? await Task.sleep(for: .seconds(1))
        if code.lowercased() == "femella2026" {
            membership = Membership(
                id: UUID().uuidString,
                userId: currentUser?.id ?? "",
                hubId: selectedHubId,
                status: .active,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
                source: .code
            )
            authState = .authenticated
            return true
        }
        return false
    }

    func signOut() {
        currentUser = nil
        membership = nil
        authState = .unauthenticated
    }

    func deleteAccount() async {
        try? await Task.sleep(for: .seconds(0.5))
        signOut()
    }
}
