import SwiftUI
import UIKit

// MARK: - Brand Colors (femella BI Design Dossier May 2024)

enum FemColor {
    // Primary
    static let darkBlue  = Color(hex: 0x203253)
    static let pink      = Color(hex: 0xF9829E)
    static let green     = Color(hex: 0x026914)

    // Secondary
    static let lightBlue = Color(hex: 0x6E97B4)
    static let orangeRed = Color(hex: 0xE8532D)
    static let ivory     = Color(hex: 0xF5ECE5)

    // Semantic aliases (keep backward compatibility)
    static let navy          = darkBlue
    static let accentPink    = pink
    static let accentPinkDark = Color(hex: 0xE0607E)
    static let ctaBlue       = lightBlue
    static let success       = green
    static let danger        = orangeRed
    static let blush         = ivory
    static let cardBackground = Color.white
    static let warmWhite     = Color(hex: 0xFAF6F3)

    // Gradients
    static let pinkGradient = LinearGradient(
        colors: [pink, Color(hex: 0xE0607E)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [darkBlue, Color(hex: 0x2E4570)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let ivoryBlueWash = LinearGradient(
        colors: [ivory, darkBlue.opacity(0.03)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Brand Typography

enum FemFont {
    // Display — Loubag (titles, hero text)
    static func display(_ size: CGFloat) -> Font {
        .custom("Loubag-Bold", size: size)
    }
    static func displayMedium(_ size: CGFloat) -> Font {
        .custom("Loubag-Medium", size: size)
    }
    static func displayLight(_ size: CGFloat) -> Font {
        .custom("Loubag-Light", size: size)
    }

    // Title — Unica One (section headers, nav titles)
    static func title(_ size: CGFloat) -> Font {
        .custom("UnicaOne-Regular", size: size)
    }

    // Body — Inter (variable font, all weights)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Spacing

enum FemSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - View Modifiers

struct FemCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FemColor.cardBackground)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(color: FemColor.darkBlue.opacity(0.06), radius: 10, y: 5)
    }
}

struct FemPrimaryButton: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.custom("Loubag-SemiBold", size: 17))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isEnabled
                    ? AnyShapeStyle(FemColor.pinkGradient)
                    : AnyShapeStyle(FemColor.pink.opacity(0.35))
            )
            .clipShape(Capsule())
            .shadow(color: FemColor.pink.opacity(isEnabled ? 0.3 : 0), radius: 8, y: 4)
    }
}

struct FemSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(FemColor.darkBlue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(FemColor.darkBlue.opacity(0.08))
            .clipShape(Capsule())
    }
}

private struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.endEditing()
                }
            )
    }
}

// MARK: - Reusable Components

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : FemColor.darkBlue)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(isSelected ? FemColor.pink : FemColor.ivory.opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : FemColor.darkBlue.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct AvatarView: View {
    let initials: String
    let url: URL?
    let size: CGFloat

    var body: some View {
        if let url {
            Color(FemColor.ivory)
                .frame(width: size, height: size)
                .overlay {
                    CachedAsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(FemColor.pink.opacity(0.3), lineWidth: 2))
        } else {
            Circle()
                .fill(FemColor.pink.opacity(0.12))
                .frame(width: size, height: size)
                .overlay {
                    Text(initials)
                        .font(FemFont.display(size * 0.36))
                        .foregroundStyle(FemColor.pink)
                }
                .overlay(Circle().strokeBorder(FemColor.pink.opacity(0.2), lineWidth: 2))
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Decorative Brand Elements

/// Overlapping circles — the signature femella brand pattern
struct CirclePattern: View {
    var size: CGFloat = 200
    var opacity: Double = 0.08

    var body: some View {
        ZStack {
            Circle()
                .fill(FemColor.pink.opacity(opacity))
                .frame(width: size, height: size)
                .offset(x: -size * 0.25, y: -size * 0.1)
            Circle()
                .fill(FemColor.lightBlue.opacity(opacity * 0.8))
                .frame(width: size * 0.75, height: size * 0.75)
                .offset(x: size * 0.2, y: size * 0.05)
            Circle()
                .fill(FemColor.green.opacity(opacity * 0.6))
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(x: -size * 0.05, y: size * 0.25)
        }
    }
}

/// "f" logo circle
struct FemLogo: View {
    var size: CGFloat = 56
    var style: LogoStyle = .pink

    enum LogoStyle {
        case pink, white, dark
    }

    var body: some View {
        let bgColor: Color = switch style {
        case .pink: FemColor.pink
        case .white: .white
        case .dark: FemColor.darkBlue
        }

        Circle()
            .fill(bgColor)
            .frame(width: size, height: size)
            .overlay {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    // If the logo has a transparent background, this handles it cleanly
                    .padding(size * 0.15) 
            }
            .shadow(color: bgColor.opacity(0.25), radius: 10, y: 4)
    }
}

// MARK: - View Extensions

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

    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
