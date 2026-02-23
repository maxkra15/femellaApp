import SwiftUI

@Observable
@MainActor
class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading: Bool = false

    private let service = SupabaseService.shared

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func loadNotifications() async {
        guard let userId = service.currentUserId else { return }
        isLoading = true
        do {
            notifications = try await service.fetchNotifications(userId: userId)
        } catch {
            print("Failed to load notifications: \(error)")
        }
        isLoading = false
    }

    func markAsRead(_ notification: AppNotification) {
        if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[idx].isRead = true
            Task {
                try? await service.markNotificationRead(id: notification.id)
            }
        }
    }

    func markAllAsRead() {
        guard let userId = service.currentUserId else { return }
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        Task {
            try? await service.markAllNotificationsRead(userId: userId)
        }
    }
}
