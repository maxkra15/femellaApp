import SwiftUI

struct NotificationsView: View {
    @Bindable var notificationsVM: NotificationsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: FemSpacing.sm) {
                    if notificationsVM.notifications.isEmpty && !notificationsVM.isLoading {
                        ContentUnavailableView("No Notifications", systemImage: "bell.slash", description: Text("You're all caught up!"))
                            .frame(minHeight: 300)
                    } else {
                        ForEach(notificationsVM.notifications) { notification in
                            NotificationRow(notification: notification) {
                                notificationsVM.markAsRead(notification)
                            }
                        }
                    }
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .background(FemColor.blush.ignoresSafeArea())
            .navigationTitle("Notifications")
            .toolbar {
                if notificationsVM.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Read All") {
                            notificationsVM.markAllAsRead()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .task {
                await notificationsVM.loadNotifications()
            }
        }
    }
}

private struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: FemSpacing.md) {
                notificationIcon
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                            .foregroundStyle(FemColor.navy)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(FemColor.accentPink)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(notification.sentAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(FemSpacing.md)
            .background(notification.isRead ? FemColor.cardBackground : FemColor.accentPink.opacity(0.04))
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var notificationIcon: some View {
        Image(systemName: iconName)
            .font(.subheadline)
            .foregroundStyle(iconColor)
    }

    private var iconName: String {
        switch notification.type {
        case .announcement: "megaphone.fill"
        case .eventUpdate: "calendar.badge.clock"
        case .system: "bell.fill"
        case .membership: "crown.fill"
        case .registration: "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .announcement: FemColor.ctaBlue
        case .eventUpdate: FemColor.accentPink
        case .system: FemColor.navy
        case .membership: .orange
        case .registration: FemColor.success
        }
    }
}
