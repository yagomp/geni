import SwiftUI

/// Pips for small targets, a thick bar with a count for larger ones.
struct BadgeProgressView: View {
    let progress: BadgeProgress
    let color: Color

    var body: some View {
        Group {
            if progress.usesPips {
                HStack(spacing: 8) {
                    ForEach(0..<progress.target, id: \.self) { index in
                        Circle()
                            .fill(index < progress.filled ? color : color.soft(0.18))
                            .overlay(Circle().stroke(GeniColor.hairline, lineWidth: 1))
                            .frame(width: 20, height: 20)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    SegmentedBar(fraction: progress.ratio, color: color)
                    Text("\(progress.filled)/\(progress.target)")
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .fixedSize()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progress.filled) / \(progress.target)")
    }
}

private struct SegmentedBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        color.soft(0.18)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    color.frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 16)
            .clipShape(GeniShape(scale: 0.6))
            .overlay(GeniShape(scale: 0.6).stroke(GeniColor.hairline, lineWidth: 1))
    }
}
