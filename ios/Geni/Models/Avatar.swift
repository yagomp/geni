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

    static let extras: [AvatarOption] = [
        AvatarOption(id: "cat", emoji: "🐱", icon: "pawprint.fill", color: .orange),
        AvatarOption(id: "dog", emoji: "🐶", icon: "pawprint.fill", color: .brown),
        AvatarOption(id: "bear", emoji: "🐻", icon: "leaf.fill", color: .brown),
        AvatarOption(id: "frog", emoji: "🐸", icon: "leaf.fill", color: .green),
        AvatarOption(id: "butterfly", emoji: "🦋", icon: "sparkle", color: .purple),
        AvatarOption(id: "dolphin", emoji: "🐬", icon: "tropicalstorm", color: .cyan),
        AvatarOption(id: "owl", emoji: "🦉", icon: "moon.fill", color: .brown),
        AvatarOption(id: "bee", emoji: "🐝", icon: "sparkle", color: .yellow),
        AvatarOption(id: "star", emoji: "⭐", icon: "star.fill", color: .yellow),
        AvatarOption(id: "rainbow", emoji: "🌈", icon: "sparkle", color: .purple),
        AvatarOption(id: "sun", emoji: "☀️", icon: "sun.max.fill", color: .orange),
        AvatarOption(id: "flower", emoji: "🌸", icon: "leaf.fill", color: .pink),
        AvatarOption(id: "wizard", emoji: "🧙", icon: "wand.and.stars", color: .purple),
        AvatarOption(id: "fairy", emoji: "🧚", icon: "sparkle", color: .pink),
        AvatarOption(id: "superhero", emoji: "🦸", icon: "bolt.fill", color: .blue),
        AvatarOption(id: "astronaut", emoji: "🧑‍🚀", icon: "paperplane.fill", color: .cyan),
    ]

    static func find(_ id: String) -> AvatarOption {
        all.first { $0.id == id } ?? extras.first { $0.id == id } ?? all[0]
    }
}
