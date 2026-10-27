import SwiftUI

/// Geni's still poses (trimmed transparent artwork in Assets.xcassets). Geni appears at the start and end
/// of things, never while a child is solving, and never sad.
enum MascotPose: String {
    case book = "MascotBook"
    case star = "MascotStar"
    case point = "MascotPoint"
    case head = "MascotHead"

    /// Width / height of the artwork.
    var aspectRatio: CGFloat {
        switch self {
        case .book: 468.0 / 720.0
        case .star: 352.0 / 720.0
        case .point: 518.0 / 720.0
        case .head: 384.0 / 318.0
        }
    }
}

/// A decorative still pose `height` points tall that springs up once from its feet (a fade under Reduce Motion).
struct MascotPoseView: View {
    let pose: MascotPose
    let height: CGFloat
    var delay: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: height * pose.aspectRatio, height: height)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.4, anchor: .bottom)
            .opacity(appeared ? 1 : 0)
            .animation(reduceMotion ? .easeOut(duration: 0.2).delay(delay)
                                    : .spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appeared)
            .onAppear { appeared = true }
            .accessibilityHidden(true)
    }
}

/// Geni cheers once, then idles; a tap cheers again. The idle still under Reduce Motion.
struct MascotCheerView: View {
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cheers = 0

    var body: some View {
        Group {
            if reduceMotion {
                Image("HeroMascot")
                    .resizable()
                    .scaledToFit()
            } else {
                MascotVideoView(intro: .cheer, cheers: cheers)
            }
        }
        .frame(width: height * MascotVideoView.aspectRatio, height: height)
        .contentShape(Rectangle())
        .onTapGesture { cheers += 1 }
        .accessibilityHidden(true)
    }
}
