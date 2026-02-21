import SwiftUI

enum FemColor {
    static let blush = Color(red: 0.96, green: 0.91, blue: 0.89)
    static let navy = Color(red: 0.13, green: 0.23, blue: 0.35)
    static let accentPink = Color(red: 0.95, green: 0.56, blue: 0.70)
    static let accentPinkDark = Color(red: 0.91, green: 0.42, blue: 0.61)
    static let ctaBlue = Color(red: 0.48, green: 0.62, blue: 0.71)
    static let success = Color(red: 0.09, green: 0.64, blue: 0.29)
    static let danger = Color(red: 0.86, green: 0.15, blue: 0.15)
    static let cardBackground = Color(red: 1.0, green: 0.98, blue: 0.97)
    static let warmWhite = Color(red: 0.99, green: 0.97, blue: 0.95)
}

enum FemSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

struct FemCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FemColor.cardBackground)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

struct FemPrimaryButton: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? FemColor.accentPink : FemColor.accentPink.opacity(0.4))
            .clipShape(.rect(cornerRadius: 14))
    }
}

struct FemSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(FemColor.ctaBlue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(FemColor.ctaBlue.opacity(0.12))
            .clipShape(.rect(cornerRadius: 12))
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : FemColor.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? FemColor.accentPink : FemColor.blush)
                .clipShape(Capsule())
        }
    }
}

struct AvatarView: View {
    let initials: String
    let url: URL?
    let size: CGFloat

    var body: some View {
        if let url {
            Color(FemColor.blush)
                .frame(width: size, height: size)
                .overlay {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())
        } else {
            Circle()
                .fill(FemColor.accentPink.opacity(0.2))
                .frame(width: size, height: size)
                .overlay {
                    Text(initials)
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(FemColor.accentPinkDark)
                }
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension View {
    func femCard() -> some View {
        modifier(FemCardStyle())
    }

    func femPrimaryButton(isEnabled: Bool = true) -> some View {
        modifier(FemPrimaryButton(isEnabled: isEnabled))
    }

    func femSecondaryButton() -> some View {
        modifier(FemSecondaryButton())
    }
}
