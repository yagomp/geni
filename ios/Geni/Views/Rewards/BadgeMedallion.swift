import SwiftUI

/// Circular badge: filled and shadowed when earned, pastel with a dashed ring (and progress arc) when not.
struct BadgeMedallion: View {
    let badge: Badge
    var size: CGFloat = 84
    var earned: Bool
    var progress: BadgeProgress?

    var body: some View {
        ZStack {
            if earned {
                Circle()
                    .fill(badge.color.soft(0.5))
                    .overlay(Circle().stroke(GeniColor.hairline, lineWidth: 1))
                    .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)
            } else {
                Circle()
                    .fill(badge.color.soft(0.18))
                Circle()
                    .inset(by: 1.5)
                    .stroke(badge.color, style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
                if let progress, progress.ratio > 0 {
                    Circle()
                        .inset(by: 3)
                        .trim(from: 0, to: progress.ratio)
                        .stroke(badge.color.deep(0.2), style: StrokeStyle(lineWidth: 6))
                        .rotationEffect(.degrees(-90))
                }
            }

            Text(badge.emoji)
                .font(.system(size: size * 0.48))
                .opacity(earned ? 1 : 0.6)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .accessibilityHidden(true)
    }
}
