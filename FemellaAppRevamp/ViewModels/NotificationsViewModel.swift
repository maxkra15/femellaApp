import SwiftUI

@Observable
@MainActor
class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading: Bool = false

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func loadNotifications() async {
        isLoading = true
        try? await Task.sleep(for: .seconds(0.3))
        notifications = MockDataService.sampleNotifications()
        isLoading = false
    }

    func markAsRead(_ notification: AppNotification) {
        if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[idx].isRead = true
        }
    }

    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }
}
