import SwiftUI

nonisolated struct AvatarOption: Identifiable, Sendable {
    let id: String
    let emoji: String
    let icon: String
    let color: Color

    static let all: [AvatarOption] = [
        AvatarOption(id: "lion", emoji: "🦁", icon: "pawprint.fill", color: .orange),
        AvatarOption(id: "unicorn", emoji: "🦄", icon: "wand.and.stars", color: .purple),
        AvatarOption(id: "robot", emoji: "🤖", icon: "cpu", color: .cyan),
        AvatarOption(id: "rocket", emoji: "🚀", icon: "paperplane.fill", color: .blue),
        AvatarOption(id: "dragon", emoji: "🐲", icon: "flame.fill", color: .red),
        AvatarOption(id: "dino", emoji: "🦕", icon: "leaf.fill", color: .green),
        AvatarOption(id: "penguin", emoji: "🐧", icon: "snowflake", color: .mint),
        AvatarOption(id: "fox", emoji: "🦊", icon: "hare.fill", color: .orange),
        AvatarOption(id: "panda", emoji: "🐼", icon: "circle.fill", color: .black),
        AvatarOption(id: "alien", emoji: "👾", icon: "sparkle", color: .purple),
        AvatarOption(id: "octopus", emoji: "🐙", icon: "tropicalstorm", color: .red),
        AvatarOption(id: "monkey", emoji: "🐵", icon: "leaf.fill", color: .brown),
    ]

    static func find(_ id: String) -> AvatarOption {
        all.first { $0.id == id } ?? all[0]
    }
}
