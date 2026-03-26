import SwiftUI

nonisolated struct Badge: Identifiable, Sendable {
    let id: String
    let titleKey: LocaleKey
    let descriptionKey: LocaleKey
    let emoji: String
    let icon: String
    let color: Color

    static let all: [Badge] = [
        Badge(id: "first_chapter", titleKey: .badgeFirstChapter, descriptionKey: .badgeFirstChapterDesc, emoji: "⭐", icon: "⭐", color: .yellow),
        Badge(id: "streak_3", titleKey: .badgeStreak3, descriptionKey: .badgeStreak3Desc, emoji: "🔥", icon: "🔥", color: .orange),
        Badge(id: "streak_7", titleKey: .badgeStreak7, descriptionKey: .badgeStreak7Desc, emoji: "🔥", icon: "🔥", color: .red),
        Badge(id: "chapters_10", titleKey: .badgeChapters10, descriptionKey: .badgeChapters10Desc, emoji: "📖", icon: "📖", color: .blue),
        Badge(id: "perfect_chapter", titleKey: .badgePerfect, descriptionKey: .badgePerfectDesc, emoji: "👑", icon: "👑", color: .purple),
        Badge(id: "fast_solver", titleKey: .badgeFastSolver, descriptionKey: .badgeFastSolverDesc, emoji: "⚡", icon: "⚡", color: .cyan),
        Badge(id: "mul_master", titleKey: .badgeMulMaster, descriptionKey: .badgeMulMasterDesc, emoji: "✖️", icon: "✖️", color: .green),
        Badge(id: "correct_100", titleKey: .badgeCorrect100, descriptionKey: .badgeCorrect100Desc, emoji: "✅", icon: "✅", color: .mint),
        Badge(id: "streak_14", titleKey: .badgeStreak14, descriptionKey: .badgeStreak14Desc, emoji: "🔥", icon: "🔥", color: .pink),
        Badge(id: "streak_30", titleKey: .badgeStreak30, descriptionKey: .badgeStreak30Desc, emoji: "🏆", icon: "🏆", color: .yellow),
        Badge(id: "first_reading", titleKey: .badgeFirstReading, descriptionKey: .badgeFirstReadingDesc, emoji: "📖", icon: "📖", color: .green),
        Badge(id: "reading_5", titleKey: .badgeReading5, descriptionKey: .badgeReading5Desc, emoji: "📚", icon: "📚", color: .teal),
        Badge(id: "reading_master", titleKey: .badgeReadingMaster, descriptionKey: .badgeReadingMasterDesc, emoji: "📕", icon: "📕", color: .indigo),
        Badge(id: "full_chapter", titleKey: .badgeFullChapter, descriptionKey: .badgeFullChapterDesc, emoji: "✅", icon: "✅", color: .orange),
    ]
}
