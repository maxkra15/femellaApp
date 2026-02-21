import Foundation

nonisolated enum MembershipStatus: String, Codable, Sendable {
    case active
    case pastDue = "past_due"
    case canceled
    case expired
    case none
}

nonisolated enum MembershipSource: String, Codable, Sendable {
    case stripe
    case code
    case comped
}

nonisolated struct Membership: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let userId: String
    let hubId: String
    let status: MembershipStatus
    let startDate: Date
    let endDate: Date
    let source: MembershipSource

    var isActive: Bool {
        status == .active && endDate > Date()
    }
}
