import Foundation

nonisolated enum RegistrationStatus: String, Codable, Sendable {
    case registered
    case waitlisted
    case canceled
    case attended
    case noShow = "no_show"
}

nonisolated struct EventRegistration: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let eventId: String
    let userId: String
    let status: RegistrationStatus
    let registeredAt: Date
    let canceledAt: Date?
    let position: Int?
}
