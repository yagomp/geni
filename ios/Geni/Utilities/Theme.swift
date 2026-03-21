import SwiftUI

enum GeniColor {
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)
    static let blue = Color(red: 0.0, green: 0.4, blue: 1.0)
    static let pink = Color(red: 1.0, green: 0.18, blue: 0.33)
    static let green = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let purple = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let orange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let cyan = Color(red: 0.4, green: 0.85, blue: 0.95)
    static let background = Color.white
    static let lightYellow = Color(red: 1.0, green: 0.97, blue: 0.88)
    static let darkBG = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let card = Color.white
    static let border = Color.black
    static let peach = Color(red: 0.96, green: 0.82, blue: 0.72)
    static let lightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
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

    init(color: Color = GeniColor.blue, textColor: Color = .white) {
        self.color = color
        self.textColor = textColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded, weight: .black))
            .foregroundStyle(textColor)
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
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
