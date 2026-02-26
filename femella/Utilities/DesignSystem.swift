import SwiftUI
import UIKit

// MARK: - Brand Colors (femella BI Design Dossier May 2024)

enum FemColor {
    // Primary
    static let darkBlue = Color(hex: 0x203253)
    static let pink = Color(hex: 0xF9829E)
    static let green = Color(hex: 0x026914)

    // Secondary
    static let lightBlue = Color(hex: 0x6E97B4)
    static let orangeRed = Color(hex: 0xE8532D)
    static let ivory = Color(hex: 0xF5ECE5)

    // Semantic aliases (keep backward compatibility)
    static let navy = darkBlue
    static let accentPink = pink
    static let accentPinkDark = Color(hex: 0xE0607E)
    static let ctaBlue = lightBlue
    static let success = green
    static let danger = orangeRed
    static let blush = ivory
    static let cardBackground = Color.white
    static let warmWhite = Color(hex: 0xFAF6F3)
    static let powderBlue = Color(hex: 0xEAF2FB)
    static let blushPink = Color(hex: 0xFCEFF3)

    // Gradients
    static let pinkGradient = LinearGradient(
        colors: [pink, Color(hex: 0xE0607E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [darkBlue, Color(hex: 0x2E4570)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ivoryBlueWash = LinearGradient(
        colors: [ivory, darkBlue.opacity(0.03)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let ambientGradient = LinearGradient(
        colors: [warmWhite, powderBlue.opacity(0.8), blushPink.opacity(0.78), ivory],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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

    // Body — Inter
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter-Regular", size: size).weight(weight)
    }

    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .custom("Inter-Regular", size: size).weight(weight)
    }

    static func ui(_ size: CGFloat = 15, weight: Font.Weight = .semibold) -> Font {
        .custom("Inter-Regular", size: size).weight(weight)
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
            .font(FemFont.ui(15, weight: .semibold))
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

private struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { proxy in
                        let width = max(proxy.size.width, 20)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(width * 0.55, 60))
                            .rotationEffect(.degrees(14))
                            .offset(x: phase * (width + 120))
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard active else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

struct FloatingLiftModifier: ViewModifier {
    var trigger: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(trigger ? 1 : 0.975)
            .opacity(trigger ? 1 : 0.4)
            .offset(y: trigger ? 0 : 8)
            .animation(.easeOut(duration: 0.45), value: trigger)
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
                .font(FemFont.ui(14, weight: .semibold))
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
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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
    enum Emphasis {
        case subtle
        case solid
    }

    let text: String
    let color: Color
    var icon: String?
    var emphasis: Emphasis = .subtle

    init(
        text: String,
        color: Color,
        icon: String? = nil,
        emphasis: Emphasis = .subtle
    ) {
        self.text = text
        self.color = color
        self.icon = icon
        self.emphasis = emphasis
    }

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(FemFont.caption(weight: .bold))
        }
        .foregroundStyle(emphasis == .solid ? Color.white : color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(backgroundStyle)
        .overlay(
            Capsule()
                .strokeBorder(
                    color.opacity(emphasis == .solid ? 0 : 0.28),
                    lineWidth: emphasis == .solid ? 0 : 1
                )
        )
        .shadow(
            color: color.opacity(emphasis == .solid ? 0.25 : 0.08),
            radius: emphasis == .solid ? 6 : 2,
            y: emphasis == .solid ? 3 : 1
        )
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        switch emphasis {
        case .subtle:
            color.opacity(0.11)
        case .solid:
            LinearGradient(
                colors: [color.opacity(0.9), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(FemColor.darkBlue.opacity(0.08))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(FemColor.darkBlue.opacity(0.1))
            .frame(width: size, height: size)
            .shimmer()
    }
}

struct GlassPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FemSpacing.lg)
            .background(Color.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(FemColor.darkBlue.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: FemColor.darkBlue.opacity(0.08), radius: 14, y: 7)
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

struct FemAmbientBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                FemColor.ambientGradient

                Circle()
                    .fill(FemColor.pink.opacity(0.16))
                    .frame(width: geo.size.width * 0.52)
                    .blur(radius: 24)
                    .offset(
                        x: animate ? geo.size.width * 0.36 : geo.size.width * 0.16,
                        y: animate ? -geo.size.height * 0.1 : -geo.size.height * 0.02
                    )

                Circle()
                    .fill(FemColor.lightBlue.opacity(0.14))
                    .frame(width: geo.size.width * 0.58)
                    .blur(radius: 30)
                    .offset(
                        x: animate ? -geo.size.width * 0.26 : -geo.size.width * 0.42,
                        y: animate ? geo.size.height * 0.55 : geo.size.height * 0.45
                    )

                Circle()
                    .fill(FemColor.green.opacity(0.1))
                    .frame(width: geo.size.width * 0.3)
                    .blur(radius: 20)
                    .offset(
                        x: animate ? -geo.size.width * 0.04 : geo.size.width * 0.12,
                        y: animate ? geo.size.height * 0.25 : geo.size.height * 0.35
                    )
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
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

    func shimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }

    func femAmbientBackground() -> some View {
        background(FemAmbientBackground())
    }

    func floatingLift(active: Bool = true) -> some View {
        modifier(FloatingLiftModifier(trigger: active))
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
