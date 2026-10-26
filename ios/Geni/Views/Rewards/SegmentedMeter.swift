import SwiftUI

/// Chunky segmented progress meter; `fraction` is 0…1 and fills segment by segment.
struct SegmentedMeter: View {
    let fraction: Double
    var color: Color = GeniColor.purple
    var segments = 10
    var height: CGFloat = 24

    var body: some View {
        let clamped = min(max(fraction, 0), 1)
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { index in
                let fill = min(max(clamped * Double(segments) - Double(index), 0), 1)
                color.soft(0.18)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            color.frame(width: geo.size.width * fill)
                        }
                    }
                    .clipShape(GeniShape(scale: 0.6))
                    .overlay(GeniShape(scale: 0.6).stroke(GeniColor.hairline, lineWidth: 1))
            }
        }
        .frame(height: height)
    }
}
