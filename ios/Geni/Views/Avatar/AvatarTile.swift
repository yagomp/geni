import SwiftUI

/// One square avatar tile; selected per spec §0 in the avatar's own tint.
struct AvatarTile: View {
    let avatar: AvatarOption
    let isSelected: Bool
    var emojiSize: CGFloat = 44
    var tileSize: CGFloat? = nil

    var body: some View {
        Text(avatar.emoji)
            .font(.system(size: emojiSize))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: tileSize, height: tileSize)
            .selectableTile(isSelected: isSelected, tint: avatar.color, restingShadow: GeniColor.border)
    }
}

/// The current-avatar square (chooser header, name step, edit form).
struct AvatarPreview: View {
    let avatar: AvatarOption
    var size: CGFloat = 120
    /// Bounce when the avatar changes.
    var bounces = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = GeniShape()
        Text(avatar.emoji)
            .font(.system(size: size * 0.6))
            .frame(width: size, height: size)
            .background(GeniColor.background)
            .clipShape(shape)
            .overlay(shape.stroke(GeniColor.hairline, lineWidth: 1))
            .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)
            .contentTransition(.opacity)
            .keyframeAnimator(initialValue: 1.0, trigger: avatar.id) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                if bounces && !reduceMotion {
                    SpringKeyframe(1.12, duration: 0.14)
                    SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                } else {
                    LinearKeyframe(1.0, duration: 0.01)
                }
            }
    }
}

enum AvatarLayout {
    /// The scrolling chooser sheet; onboarding supplies columns from its available size.
    static let adaptiveColumns = [GridItem(.adaptive(minimum: 72, maximum: 96), spacing: 12)]
}

/// A grid of selectable avatar tiles. Identifiers are `<idPrefix>.<avatar id>`.
struct AvatarGrid: View {
    let options: [AvatarOption]
    @Binding var selection: String
    var idPrefix: String = "avatar"
    var columns: [GridItem] = AvatarLayout.adaptiveColumns
    var spacing: CGFloat = 12
    var emojiSize: CGFloat = 44
    var tileSize: CGFloat? = nil

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(options) { avatar in
                Button {
                    HapticManager.selection()
                    selection = avatar.id
                } label: {
                    AvatarTile(avatar: avatar, isSelected: selection == avatar.id, emojiSize: emojiSize, tileSize: tileSize)
                }
                .buttonStyle(KidPressStyle())
                .accessibilityIdentifier("\(idPrefix).\(avatar.id)")
            }
        }
    }
}
