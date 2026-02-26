import SwiftUI

struct NotificationsView: View {
    @Bindable var notificationsVM: NotificationsViewModel
    @State private var isExpanded = false

    private var displayedNotifications: [AppNotification] {
        if isExpanded {
            return notificationsVM.notifications
        }
        return Array(notificationsVM.notifications.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: FemSpacing.sm) {
                    if notificationsVM.isLoading {
                        loadingSkeleton
                    } else if notificationsVM.notifications.isEmpty {
                        ContentUnavailableView("No Notifications", systemImage: "bell.slash", description: Text("You're all caught up!"))
                            .frame(minHeight: 300)
                    } else {
                        ForEach(displayedNotifications) { notification in
                            NotificationRow(notification: notification) {
                                notificationsVM.markAsRead(notification)
                            }
                        }

                        if notificationsVM.notifications.count > 5 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(isExpanded ? "Collapse" : "Expand")
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption2.weight(.semibold))
                                }
                                .font(FemFont.caption(weight: .medium))
                                .foregroundStyle(FemColor.darkBlue.opacity(0.7))
                                .padding(.top, FemSpacing.xs)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, FemSpacing.lg)
                .padding(.bottom, FemSpacing.xxl)
            }
            .femAmbientBackground()
            .navigationTitle("Notifications")
            .toolbar {
                if notificationsVM.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Read All") {
                            notificationsVM.markAllAsRead()
                        }
                        .font(FemFont.ui(15, weight: .semibold))
                        .foregroundStyle(FemColor.pink)
                    }
                }
            }
            .task {
                await notificationsVM.loadNotifications()
            }
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: FemSpacing.sm) {
            ForEach(0..<6, id: \.self) { _ in
                NotificationRowSkeleton()
            }
        }
        .padding(.top, FemSpacing.xs)
    }
}

private struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: FemSpacing.md) {
                Circle()
                    .fill(iconColor.opacity(notification.isRead ? 0.12 : 0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(FemFont.body(15, weight: notification.isRead ? .medium : .semibold))
                            .foregroundStyle(FemColor.darkBlue)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(FemColor.pink)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.body)
                        .font(FemFont.caption(13, weight: .regular))
                        .foregroundStyle(FemColor.darkBlue.opacity(0.5))
                        .lineLimit(2)

                    Text(timeSinceText)
                        .font(FemFont.caption(11, weight: .medium))
                        .foregroundStyle(FemColor.darkBlue.opacity(0.3))
                }
            }
            .padding(FemSpacing.md)
            .background(cardBackground)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        notification.isRead ? FemColor.darkBlue.opacity(0.08) : FemColor.pink.opacity(0.22),
                        lineWidth: 1
                    )
            )
            .shadow(color: FemColor.darkBlue.opacity(notification.isRead ? 0.04 : 0.08), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: notification.isRead
                ? [Color.white.opacity(0.78), FemColor.powderBlue.opacity(0.34)]
                : [Color.white.opacity(0.94), FemColor.pink.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    private var timeSinceText: String {
        let elapsed = max(0, Date().timeIntervalSince(notification.sentAt))
        if elapsed < 3600 {
            return "Under 1h ago"
        }
        if elapsed < 86_400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        }
        let days = Int(elapsed / 86_400)
        return "\(days)d ago"
    }
}

private struct NotificationRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: FemSpacing.md) {
            SkeletonCircle(size: 40)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 190, height: 14, cornerRadius: 7)
                SkeletonBlock(height: 12, cornerRadius: 6)
                SkeletonBlock(width: 120, height: 10, cornerRadius: 5)
            }
        }
        .padding(FemSpacing.md)
        .background(Color.white.opacity(0.72))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
        )
    }
}
