import Foundation

nonisolated enum NotificationType: String, Codable, Sendable {
    case announcement
    case eventUpdate = "event_update"
    case system
    case membership
    case registration
}

nonisolated struct AppNotification: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let hubId: String?
    let title: String
    let body: String
    let type: NotificationType
    let sentAt: Date
    var isRead: Bool
}
