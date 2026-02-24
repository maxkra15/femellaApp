import Foundation

nonisolated struct UserProfile: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var university: String
    var degree: String
    var company: String
    var jobTitle: String
    var homeHubId: String
    var avatarURL: URL?
    var showProfileToMembers: Bool
    var linkedinUrl: String?
    var birthday: Date?
    var funFacts: String?
    var hobbies: String?
    var likesSports: Bool
    var interestedInRunningClub: Bool
    var interestedInCyclingClub: Bool

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return "\(f)\(l)"
    }

    var isProfileComplete: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty &&
        !university.isEmpty && !company.isEmpty && !jobTitle.isEmpty && !homeHubId.isEmpty
    }
}
