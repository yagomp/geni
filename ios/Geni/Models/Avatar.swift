import SwiftUI

nonisolated struct AvatarOption: Identifiable, Sendable, Hashable {
    /// Persisted in `ChildProfile.avatarId`; never rename.
    let id: String
    let emoji: String
    /// The avatar's own tint (selected fill, coloured shadow); never black.
    let tint: AvatarTint

    /// The 12 starters, in their original order.
    static let all: [AvatarOption] = [
        AvatarOption(id: "lion", emoji: "🦁", tint: .orange),
        AvatarOption(id: "unicorn", emoji: "🦄", tint: .purple),
        AvatarOption(id: "robot", emoji: "🤖", tint: .cyan),
        AvatarOption(id: "rocket", emoji: "🚀", tint: .pink),
        AvatarOption(id: "dragon", emoji: "🐲", tint: .green),
        AvatarOption(id: "dino", emoji: "🦕", tint: .yellow),
        AvatarOption(id: "penguin", emoji: "🐧", tint: .blue),
        AvatarOption(id: "fox", emoji: "🦊", tint: .orange),
        AvatarOption(id: "panda", emoji: "🐼", tint: .cyan),
        AvatarOption(id: "alien", emoji: "👾", tint: .purple),
        AvatarOption(id: "octopus", emoji: "🐙", tint: .pink),
        AvatarOption(id: "monkey", emoji: "🐵", tint: .yellow),
    ]

    static let extras: [AvatarOption] = [
        AvatarOption(id: "cat", emoji: "🐱", tint: .yellow),
        AvatarOption(id: "dog", emoji: "🐶", tint: .orange),
        AvatarOption(id: "bear", emoji: "🐻", tint: .orange),
        AvatarOption(id: "frog", emoji: "🐸", tint: .green),
        AvatarOption(id: "butterfly", emoji: "🦋", tint: .blue),
        AvatarOption(id: "dolphin", emoji: "🐬", tint: .cyan),
        AvatarOption(id: "owl", emoji: "🦉", tint: .purple),
        AvatarOption(id: "bee", emoji: "🐝", tint: .yellow),
        AvatarOption(id: "star", emoji: "⭐", tint: .yellow),
        AvatarOption(id: "rainbow", emoji: "🌈", tint: .purple),
        AvatarOption(id: "sun", emoji: "☀️", tint: .orange),
        AvatarOption(id: "flower", emoji: "🌸", tint: .pink),
        AvatarOption(id: "wizard", emoji: "🧙", tint: .purple),
        AvatarOption(id: "fairy", emoji: "🧚", tint: .pink),
        AvatarOption(id: "superhero", emoji: "🦸", tint: .blue),
        AvatarOption(id: "astronaut", emoji: "🧑‍🚀", tint: .cyan),
    ]

    /// Every avatar in display order: starters, then extras.
    static let catalog: [AvatarOption] = all + extras

    /// Number of tiles in the onboarding quick grid (plus the "more" tile).
    static let quickCount = 7

    static func find(_ id: String) -> AvatarOption {
        catalog.first { $0.id == id } ?? all[0]
    }

    /// The onboarding quick grid: the first seven starters. An avatar from outside them (the
    /// current selection, else the last one picked from the full chooser) takes slot 7, so the
    /// grid never grows a ninth tile.
    static func quickPicks(selected: String, pinned: String? = nil) -> [AvatarOption] {
        var picks = Array(all.prefix(quickCount))
        let isQuick = { (id: String) in picks.contains { $0.id == id } }
        let extra = !isQuick(selected) ? selected : pinned.flatMap { isQuick($0) ? nil : $0 }
        if let extra, catalog.contains(where: { $0.id == extra }) {
            picks[quickCount - 1] = find(extra)
        }
        return picks
    }
}

/// Avatar tints: the GeniColor palette only.
nonisolated enum AvatarTint: String, Sendable, Hashable, CaseIterable {
    case yellow, blue, pink, green, purple, orange, cyan
}

extension AvatarOption {
    var color: Color {
        switch tint {
        case .yellow: return GeniColor.yellow
        case .blue: return GeniColor.blue
        case .pink: return GeniColor.pink
        case .green: return GeniColor.green
        case .purple: return GeniColor.purple
        case .orange: return GeniColor.orange
        case .cyan: return GeniColor.cyan
        }
    }
}
