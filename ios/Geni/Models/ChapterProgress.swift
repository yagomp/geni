import Foundation

nonisolated struct ChapterProgress: Codable, Identifiable, Sendable {
    let id: String
    let childId: String
    let date: String
    var chapterType: ChapterType
    var status: ChapterStatus
    var exerciseResults: [ExerciseResult]
    var stars: Int
    var coinsEarned: Int
    var completedAt: Date?

    init(childId: String, date: String, chapterType: ChapterType = .daily) {
        self.id = UUID().uuidString
        self.childId = childId
        self.date = date
        self.chapterType = chapterType
        self.status = .inProgress
        self.exerciseResults = []
        self.stars = 0
        self.coinsEarned = 0
    }

    var correctCount: Int {
        exerciseResults.filter(\.wasCorrect).count
    }

    var wrongCount: Int {
        exerciseResults.count - correctCount
    }

    var firstTryCount: Int {
        exerciseResults.filter(\.firstAttemptCorrect).count
    }

    var isComplete: Bool {
        exerciseResults.count >= 20
    }

    mutating func calculateRewards() {
        let total = exerciseResults.count
        guard total > 0 else { return }

        let accuracy = Double(correctCount) / Double(total)
        if accuracy >= 0.95 {
            stars = 5
        } else if accuracy >= 0.85 {
            stars = 4
        } else if accuracy >= 0.75 {
            stars = 3
        } else if accuracy >= 0.6 {
            stars = 2
        } else {
            stars = 1
        }

        var coins = 20
        if stars >= 4 { coins += 10 }
        if stars == 5 { coins += 10 }
        if firstTryCount >= 15 { coins += 10 }
        if chapterType != .daily { coins += 10 }
        coinsEarned = coins
    }
}

nonisolated enum ChapterStatus: String, Codable, Sendable {
    case inProgress
    case completed
}

nonisolated enum ChapterType: String, Codable, Sendable {
    case daily
    case timeAttack
    case perfectRun
    case boss
    case streak
    case operationSpotlight
}
