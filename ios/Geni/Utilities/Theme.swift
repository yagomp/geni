import SwiftUI

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    var current: AppTheme = .standard
    var cornerStyle: CornerStyle = .sharp

    /// Corner radius for cards, tiles and buttons in the active profile's style.
    var cornerRadius: CGFloat { cornerStyle.radius }

    func apply(_ profile: ChildProfile) {
        current = profile.theme
        cornerStyle = profile.cornerStyle ?? .sharp
    }

    var accent: Color {
        switch current {
        case .standard: return Color(red: 0.0, green: 0.4, blue: 1.0)
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }

    var screenBackground: Color {
        switch current {
        case .standard: return Color(red: 1.0, green: 0.97, blue: 0.88)
        case .ocean: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.93, blue: 0.95)
        }
    }

    var cardBackground: Color {
        switch current {
        case .standard: return Color.white
        case .ocean: return Color(red: 0.95, green: 0.97, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.97, blue: 0.98)
        }
    }

    var progressAccent: Color {
        switch current {
        case .standard: return Color(red: 0.0, green: 0.4, blue: 1.0)
        case .ocean: return Color(red: 0.15, green: 0.5, blue: 0.85)
        case .blossom: return Color(red: 0.85, green: 0.3, blue: 0.55)
        }
    }

    var buttonColor: Color {
        switch current {
        case .standard: return Color(red: 0.0, green: 0.4, blue: 1.0)
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }
}

enum GeniColor {
    private static var theme: ThemeManager { ThemeManager.shared }

    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)
    static let blue = Color(red: 0.0, green: 0.4, blue: 1.0)
    static let pink = Color(red: 1.0, green: 0.18, blue: 0.33)
    static let green = Color(red: 0.13, green: 0.66, blue: 0.29)
    static let purple = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let orange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let cyan = Color(red: 0.4, green: 0.85, blue: 0.95)
    static let background = Color.white
    static var lightYellow: Color { theme.screenBackground }
    static let darkBG = Color(red: 0.12, green: 0.12, blue: 0.14)
    static var card: Color { theme.cardBackground }
    static let border = Color.black
    static let peach = Color(red: 0.96, green: 0.82, blue: 0.72)
    static let lightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    /// Readable text on pink tints (pink itself is too light on `pink.soft`).
    static let pinkDeep = Color(red: 0.78, green: 0.05, blue: 0.22)

    static var accent: Color { theme.accent }
}

extension Color {
    /// An opaque tint: this colour mixed into white. Use instead of `.opacity()` for fills
    /// that sit on a black offset shadow, which would otherwise show through as dark grey.
    func soft(_ amount: Double) -> Color {
        let c = resolve(in: EnvironmentValues())
        return Color(
            red: 1 - (1 - Double(c.red)) * amount,
            green: 1 - (1 - Double(c.green)) * amount,
            blue: 1 - (1 - Double(c.blue)) * amount
        )
    }

    /// Black or white, whichever reads better on this colour (e.g. black on yellow/cyan).
    /// A darker tone of this colour, for coloured offset shadows on selected states instead of black.
    func deep(_ amount: Double = 0.35) -> Color {
        let c = resolve(in: EnvironmentValues())
        return Color(
            red: Double(c.red) * (1 - amount),
            green: Double(c.green) * (1 - amount),
            blue: Double(c.blue) * (1 - amount)
        )
    }

    var readableText: Color {
        let c = resolve(in: EnvironmentValues())
        let luminance = 0.2126 * c.linearRed + 0.7152 * c.linearGreen + 0.0722 * c.linearBlue
        return luminance > 0.3 ? GeniColor.border : .white
    }
}

/// The app's card/tile/button shape: square or rounded depending on the active profile.
/// Use instead of `Rectangle()` for anything with a border or offset shadow.
struct GeniShape: Shape {
    var radius: CGFloat

    /// `scale` shrinks the radius for small tiles so they don't turn into circles.
    init(scale: CGFloat = 1) {
        radius = ThemeManager.shared.cornerRadius * scale
    }

    init(radius: CGFloat) {
        self.radius = radius
    }

    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: min(radius, min(rect.width, rect.height) / 2), style: .continuous).path(in: rect)
    }
}

extension CornerStyle {
    var radius: CGFloat { self == .rounded ? 16 : 0 }
}

extension EnvironmentValues {
    /// Local corner-radius override for previewing a style that isn't the active profile's
    /// (profile creation/editing). Nil = the active profile's style.
    @Entry var geniCornerRadius: CGFloat? = nil
}

extension GeniShape {
    /// Honours a `\.geniCornerRadius` override, read by the calling view.
    init(scale: CGFloat = 1, override radius: CGFloat?) {
        self.init(radius: (radius ?? ThemeManager.shared.cornerRadius) * scale)
    }
}

struct BrutalistCard: ViewModifier {
    var color: Color
    var borderWidth: CGFloat
    @Environment(\.geniCornerRadius) private var radiusOverride

    func body(content: Content) -> some View {
        content
            .background(color)
            .background(GeniColor.background)
            .clipShape(GeniShape(override: radiusOverride))
            .overlay(
                GeniShape(override: radiusOverride)
                    .stroke(GeniColor.border, lineWidth: borderWidth)
                    .allowsHitTesting(false)
            )
            .background(
                GeniShape(override: radiusOverride)
                    .fill(GeniColor.border)
                    .offset(x: 4, y: 4)
            )
            .compositingGroup()
    }
}

struct BrutalistButton: ButtonStyle {
    let color: Color
    let textColor: Color
    var fontSize: CGFloat?
    var verticalPadding: CGFloat?
    @Environment(\.geniCornerRadius) private var radiusOverride

    init(color: Color = ThemeManager.shared.buttonColor, textColor: Color? = nil, fontSize: CGFloat? = nil, verticalPadding: CGFloat? = nil) {
        self.color = color
        self.textColor = textColor ?? color.readableText
        self.fontSize = fontSize
        self.verticalPadding = verticalPadding
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize ?? (iPadScale.isIPad ? 24 : 20), weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, iPadScale.largePadding)
            .padding(.vertical, verticalPadding ?? (iPadScale.isIPad ? 24 : 18))
            .frame(maxWidth: .infinity)
            .background(color)
            .background(GeniColor.background)
            .clipShape(GeniShape(override: radiusOverride))
            .overlay(
                GeniShape(override: radiusOverride)
                    .stroke(GeniColor.border, lineWidth: 4)
            )
            .background(
                GeniShape(override: radiusOverride)
                    .fill(GeniColor.border)
                    .offset(x: configuration.isPressed ? 1 : 4, y: configuration.isPressed ? 1 : 4)
            )
            .compositingGroup()
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.1), value: configuration.isPressed)
    }
}

/// Press feedback for custom-drawn tiles: a small push and bounce. Replaces the system
/// style, whose press/disabled fade lets the black offset shadow show through the tile.
struct KidPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .compositingGroup()
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func brutalistCard(color: Color = GeniColor.card, borderWidth: CGFloat = 3) -> some View {
        modifier(BrutalistCard(color: color, borderWidth: borderWidth))
    }
}

enum iPadScale {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    /// Match the first iPad pass: phone-sized and short windows retain compact controls.
    static func isExpanded(in size: CGSize) -> Bool {
        isIPad && size.width >= 700 && size.height >= 800
    }
    static var factor: CGFloat { isIPad ? 1.35 : 1.0 }
    static func value(_ base: CGFloat) -> CGFloat { base * factor }
    static var padding: CGFloat { isIPad ? 40 : 20 }
    static var largePadding: CGFloat { isIPad ? 56 : 32 }
}

/// Passed by width-aware screen containers; compact iPad windows keep the phone controls.
private struct GeniExpandedLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var geniExpandedLayout: Bool {
        get { self[GeniExpandedLayoutKey.self] }
        set { self[GeniExpandedLayoutKey.self] = newValue }
    }
}

/// Supplies available space to learning screens without using device-wide screen bounds.
/// The content owns its widths; backgrounds and celebration effects still fill the window.
struct GeniLearningLayout<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .environment(\.geniExpandedLayout, iPadScale.isExpanded(in: geometry.size))
                .environment(\.geniLearningSize, geometry.size)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

extension EnvironmentValues {
    @Entry var geniLearningSize: CGSize = .zero
}

/// Square back button used on kid screens instead of the "◀️" emoji.
struct KidBackButton: View {
    let action: () -> Void
    @Environment(\.geniCornerRadius) private var radiusOverride

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(GeniColor.border)
                .frame(width: 56, height: 56)
                // A ShapeStyle background touching the top safe area can extend behind
                // the status bar. Bound the back button's white fill to its own shape.
                .background(GeniColor.card, in: GeniShape(override: radiusOverride))
                .overlay(GeniShape(override: radiusOverride).stroke(GeniColor.border, lineWidth: 3))
                .background(GeniShape(override: radiusOverride).fill(GeniColor.border).offset(x: 3, y: 3))
        }
        .buttonStyle(KidPressStyle())
        .accessibilityLabel(L.s(.back))
    }
}
