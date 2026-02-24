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
            .background(FemColor.ivoryBlueWash.ignoresSafeArea())
            .navigationTitle("Notifications")
            .toolbar {
                if notificationsVM.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Read All") {
                            notificationsVM.markAllAsRead()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FemColor.pink)
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
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: iconName)
                            .font(.body)
                            .foregroundStyle(iconColor)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                            .foregroundStyle(FemColor.darkBlue)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(FemColor.pink)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        .lineLimit(2)

                    Text(notification.sentAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(FemColor.darkBlue.opacity(0.3))
                }
            }
            .padding(FemSpacing.md)
            .background(notification.isRead ? FemColor.cardBackground : FemColor.pink.opacity(0.04))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        FemColor.darkBlue.opacity(notification.isRead ? 0.06 : 0.1),
                        lineWidth: 1
                    )
            )
            .shadow(color: FemColor.darkBlue.opacity(notification.isRead ? 0.02 : 0.04), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
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
        case .announcement: FemColor.lightBlue
        case .eventUpdate: FemColor.pink
        case .system: FemColor.darkBlue
        case .membership: FemColor.orangeRed
        case .registration: FemColor.green
        }
    }
}
