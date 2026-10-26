import SwiftUI

/// Yellow disc with a star and the level numeral. Shared by the rewards hero and the level-up popup.
struct LevelMedallion: View {
    let level: Int
    var size: CGFloat = 88

    var body: some View {
        VStack(spacing: -size * 0.04) {
            Text("⭐")
                .font(.system(size: size * 0.28))
            Text("\(level)")
                .font(.system(size: size * 0.46, weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
        .background(GeniColor.yellow, in: Circle())
        .overlay(Circle().stroke(GeniColor.hairline, lineWidth: 1))
        .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)
        .compositingGroup()
        .accessibilityHidden(true)
    }
}
