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
    var authState: AuthState = .loading
    var currentUser: UserProfile?
    var membership: Membership?
    var selectedHubId: String = ""
    var hubs: [Hub] = []
    var errorMessage: String?

    private let service = SupabaseService.shared

    var selectedHub: Hub? {
        hubs.first { $0.id == selectedHubId }
    }

    var isMembershipActive: Bool {
        membership?.isActive ?? false
    }

    // MARK: - Session Restore

    func restoreSession() async {
        authState = .loading
        do {
            hubs = try await service.fetchHubs()
        } catch {
            print("Failed to fetch hubs: \(error)")
        }

        guard let authUser = await service.restoreSession() else {
            authState = .unauthenticated
            return
        }

        await loadUserData(userId: authUser.id)
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async {
        authState = .loading
        errorMessage = nil
        do {
            let authUser = try await service.signIn(email: email, password: password)
            if hubs.isEmpty {
                hubs = try await service.fetchHubs()
            }
            await loadUserData(userId: authUser.id)
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }

    func signUp(email: String, password: String) async {
        authState = .loading
        errorMessage = nil
        do {
            let authUser = try await service.signUp(email: email, password: password)
            if hubs.isEmpty {
                hubs = try await service.fetchHubs()
            }
            currentUser = UserProfile(
                id: authUser.id,
                firstName: "",
                lastName: "",
                email: authUser.email,
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
        } catch {
            errorMessage = error.localizedDescription
            authState = .unauthenticated
        }
    }

    func completeProfile(_ profile: UserProfile) async {
        authState = .loading
        do {
            try await service.upsertProfile(profile)
            currentUser = profile
            if !profile.homeHubId.isEmpty {
                selectedHubId = profile.homeHubId
            }
            // Check if they have an active membership
            let mem = try await service.fetchMembership(userId: profile.id)
            if let mem, mem.isActive {
                membership = mem
                authState = .authenticated
            } else {
                authState = .paywalled
            }
        } catch {
            errorMessage = error.localizedDescription
            authState = .profileIncomplete
        }
    }

    func activateMembership() async {
        guard let user = currentUser else { return }
        do {
            let mem = try await service.createMembership(
                userId: user.id,
                hubId: selectedHubId,
                source: "stripe"
            )
            membership = mem
            authState = .authenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func redeemCode(_ code: String) async -> Bool {
        guard let user = currentUser else { return false }
        if code.lowercased() == "femella2026" {
            do {
                let mem = try await service.createMembership(
                    userId: user.id,
                    hubId: selectedHubId,
                    source: "code"
                )
                membership = mem
                authState = .authenticated
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        }
        return false
    }

    func signOut() {
        Task {
            try? await service.signOut()
        }
        currentUser = nil
        membership = nil
        authState = .unauthenticated
    }

    func deleteAccount() async {
        do {
            try await service.deleteAccount()
        } catch {
            print("Delete account error: \(error)")
        }
        currentUser = nil
        membership = nil
        authState = .unauthenticated
    }

    // MARK: - Private

    private func loadUserData(userId: String) async {
        do {
            let profile = try await service.fetchProfile(userId: userId)
            currentUser = profile

            if let profile, profile.isProfileComplete {
                if !profile.homeHubId.isEmpty {
                    selectedHubId = profile.homeHubId
                } else if let firstHub = hubs.first {
                    selectedHubId = firstHub.id
                }

                let mem = try await service.fetchMembership(userId: userId)
                membership = mem
                if mem?.isActive == true {
                    authState = .authenticated
                } else {
                    authState = .paywalled
                }
            } else {
                // Profile exists but is incomplete
                if currentUser == nil {
                    currentUser = UserProfile(
                        id: userId,
                        firstName: "",
                        lastName: "",
                        email: "",
                        phone: "",
                        university: "",
                        degree: "",
                        company: "",
                        jobTitle: "",
                        homeHubId: "",
                        avatarURL: nil,
                        showProfileToMembers: true
                    )
                }
                authState = .profileIncomplete
            }
        } catch {
            print("Load user data error: \(error)")
            authState = .unauthenticated
        }
    }
}
