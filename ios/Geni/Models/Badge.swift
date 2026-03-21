import SwiftUI

nonisolated struct Badge: Identifiable, Sendable {
    let id: String
    let titleKey: LocaleKey
    let descriptionKey: LocaleKey
    let icon: String
    let color: Color

    static let all: [Badge] = [
        Badge(id: "first_chapter", titleKey: .badgeFirstChapter, descriptionKey: .badgeFirstChapterDesc, icon: "star.fill", color: .yellow),
        Badge(id: "streak_3", titleKey: .badgeStreak3, descriptionKey: .badgeStreak3Desc, icon: "flame.fill", color: .orange),
        Badge(id: "streak_7", titleKey: .badgeStreak7, descriptionKey: .badgeStreak7Desc, icon: "flame.fill", color: .red),
        Badge(id: "chapters_10", titleKey: .badgeChapters10, descriptionKey: .badgeChapters10Desc, icon: "book.fill", color: .blue),
        Badge(id: "perfect_chapter", titleKey: .badgePerfect, descriptionKey: .badgePerfectDesc, icon: "crown.fill", color: .purple),
        Badge(id: "fast_solver", titleKey: .badgeFastSolver, descriptionKey: .badgeFastSolverDesc, icon: "bolt.fill", color: .cyan),
        Badge(id: "mul_master", titleKey: .badgeMulMaster, descriptionKey: .badgeMulMasterDesc, icon: "multiply.circle.fill", color: .green),
        Badge(id: "correct_100", titleKey: .badgeCorrect100, descriptionKey: .badgeCorrect100Desc, icon: "checkmark.seal.fill", color: .mint),
        Badge(id: "streak_14", titleKey: .badgeStreak14, descriptionKey: .badgeStreak14Desc, icon: "flame.fill", color: .pink),
        Badge(id: "streak_30", titleKey: .badgeStreak30, descriptionKey: .badgeStreak30Desc, icon: "trophy.fill", color: .yellow),
        Badge(id: "first_reading", titleKey: .badgeFirstReading, descriptionKey: .badgeFirstReadingDesc, icon: "book.fill", color: .green),
        Badge(id: "reading_5", titleKey: .badgeReading5, descriptionKey: .badgeReading5Desc, icon: "books.vertical.fill", color: .teal),
        Badge(id: "reading_master", titleKey: .badgeReadingMaster, descriptionKey: .badgeReadingMasterDesc, icon: "text.book.closed.fill", color: .indigo),
        Badge(id: "full_chapter", titleKey: .badgeFullChapter, descriptionKey: .badgeFullChapterDesc, icon: "checkmark.seal.fill", color: .orange),
    ]
}
