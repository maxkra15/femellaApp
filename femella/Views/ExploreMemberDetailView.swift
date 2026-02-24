import SwiftUI

struct ExploreMemberDetailView: View {
    let profile: UserProfile
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: FemSpacing.xl) {
                // Header
                VStack(spacing: 12) {
                    AvatarView(initials: profile.initials, url: profile.avatarURL, size: 100)
                        .shadow(color: FemColor.darkBlue.opacity(0.1), radius: 10, y: 5)
                    
                    VStack(spacing: 4) {
                        Text(profile.fullName)
                            .font(FemFont.display(24))
                            .foregroundStyle(FemColor.darkBlue)
                        
                        Text(profile.jobTitle + " @ " + profile.company)
                            .font(.subheadline)
                            .foregroundStyle(FemColor.darkBlue.opacity(0.6))
                    }
                    
                    if let linkedinUrl = profile.linkedinUrl, !linkedinUrl.isEmpty, let url = URL(string: linkedinUrl) {
                        Button {
                            openURL(url)
                        } label: {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("Connect on LinkedIn")
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(FemColor.pink.opacity(0.1))
                            .foregroundStyle(FemColor.pink)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, FemSpacing.lg)
                
                // Details Card
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
                .padding(FemSpacing.lg)
                .femCard()
                .padding(.horizontal, FemSpacing.lg)
            }
            .padding(.bottom, FemSpacing.xxl)
        }
        .background(FemColor.ivory.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
                    .font(.caption)
                    .foregroundStyle(FemColor.darkBlue.opacity(0.4))
                Text(value)
                    .font(.body)
                    .foregroundStyle(FemColor.darkBlue)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
