import SwiftUI

struct ExploreMemberDetailView: View {
    let profile: UserProfile
    var transitionNamespace: Namespace.ID? = nil
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if let transitionNamespace {
                mainContent
                    .navigationTransition(.zoom(sourceID: profile.id, in: transitionNamespace))
            } else {
                mainContent
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: FemSpacing.xl) {
                VStack(spacing: 12) {
                    AvatarView(initials: profile.initials, url: profile.avatarURL, size: 100)
                        .shadow(color: FemColor.darkBlue.opacity(0.1), radius: 10, y: 5)

                    VStack(spacing: 4) {
                        Text(profile.fullName)
                            .font(FemFont.display(24))
                            .foregroundStyle(FemColor.darkBlue)

                        if !headlineText.isEmpty {
                            Text(headlineText)
                                .font(FemFont.body(15, weight: .medium))
                                .foregroundStyle(FemColor.darkBlue.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                    }

                    if let linkedinUrl = profile.linkedinUrl, !linkedinUrl.isEmpty, let url = URL(string: linkedinUrl) {
                        Button {
                            openURL(url)
                        } label: {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("Connect on LinkedIn")
                            }
                            .font(FemFont.ui(15, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(FemColor.pink.opacity(0.1))
                            .foregroundStyle(FemColor.pink)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, FemSpacing.lg)

                GlassPanel {
                    VStack(spacing: 0) {
                        MemberDetailRow(icon: "graduationcap.fill", label: "University", value: profile.university)
                        Divider().padding(.leading, 44)
                        MemberDetailRow(icon: "text.book.closed.fill", label: "Degree", value: profile.degree)

                        if let facts = profile.funFacts, !facts.isEmpty {
                            Divider().padding(.leading, 44)
                            MemberDetailRow(icon: "star.fill", label: "Fun Facts", value: facts)
                        }
                        if let hobbies = profile.hobbies, !hobbies.isEmpty {
                            Divider().padding(.leading, 44)
                            MemberDetailRow(icon: "heart.fill", label: "Hobbies", value: hobbies)
                        }
                        if profile.likesSports {
                            Divider().padding(.leading, 44)
                            let text = "Likes Sports" + (profile.interestedInRunningClub ? ", Running Club" : "") + (profile.interestedInCyclingClub ? ", Cycling Club" : "")
                            MemberDetailRow(
                                icon: "figure.run.circle.fill",
                                label: "Sports",
                                value: text
                            )
                        }
                    }
                }
                .padding(.horizontal, FemSpacing.lg)
            }
            .padding(.bottom, FemSpacing.xxl)
        }
        .femAmbientBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headlineText: String {
        let left = profile.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = profile.company.trimmingCharacters(in: .whitespacesAndNewlines)

        if left.isEmpty { return right }
        if right.isEmpty { return left }
        return "\(left) @ \(right)"
    }
}

private struct MemberDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(FemColor.pink.opacity(0.08))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(FemColor.pink)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(FemFont.caption(12, weight: .medium))
                    .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                Text(value)
                    .font(FemFont.body(15))
                    .foregroundStyle(FemColor.darkBlue)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
