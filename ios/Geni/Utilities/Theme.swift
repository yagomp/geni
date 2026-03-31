import SwiftUI

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    var current: AppTheme = .standard

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
    static let green = Color(red: 0.2, green: 0.78, blue: 0.35)
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

    static var accent: Color { theme.accent }
}

struct BrutalistCard: ViewModifier {
    var color: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(color)
            .clipShape(.rect(cornerRadius: 0))
            .overlay(
                Rectangle()
                    .stroke(GeniColor.border, lineWidth: borderWidth)
                    .allowsHitTesting(false)
            )
            .background(
                Rectangle()
                    .fill(GeniColor.border)
                    .offset(x: 4, y: 4)
            )
    }
}

struct BrutalistButton: ButtonStyle {
    let color: Color
    let textColor: Color

    init(color: Color = ThemeManager.shared.buttonColor, textColor: Color = .white) {
        self.color = color
        self.textColor = textColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: iPadScale.isIPad ? 24 : 20, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, iPadScale.largePadding)
            .padding(.vertical, iPadScale.isIPad ? 24 : 18)
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(.rect(cornerRadius: 0))
            .overlay(
                Rectangle()
                    .stroke(GeniColor.border, lineWidth: 4)
            )
            .background(
                Rectangle()
                    .fill(GeniColor.border)
                    .offset(x: configuration.isPressed ? 1 : 4, y: configuration.isPressed ? 1 : 4)
            )
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
            .animation(.snappy(duration: 0.1), value: configuration.isPressed)
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
    static var factor: CGFloat { isIPad ? 1.35 : 1.0 }
    static func value(_ base: CGFloat) -> CGFloat { base * factor }
    static var padding: CGFloat { isIPad ? 40 : 20 }
    static var largePadding: CGFloat { isIPad ? 56 : 32 }
}
