import Foundation

nonisolated struct ChapterProgress: Codable, Identifiable, Sendable {
    let id: String
    let childId: String
    let date: String
    var chapterType: ChapterType
    var status: ChapterStatus
    var completedExerciseCount: Int
    /// Exercises in the chapter as generated: `ChildProfile.dailyExerciseCount` (10 for ages 4–5, else 20).
    var exerciseCount: Int
    var exerciseResults: [ExerciseResult]
    var stars: Int
    var coinsEarned: Int
    var completedAt: Date?

    init(childId: String, date: String, chapterType: ChapterType = .daily, exerciseCount: Int = 20) {
        self.id = UUID().uuidString
        self.childId = childId
        self.date = date
        self.chapterType = chapterType
        self.status = .inProgress
        self.completedExerciseCount = 0
        self.exerciseCount = exerciseCount
        self.exerciseResults = []
        self.stars = 0
        self.coinsEarned = 0
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case childId
        case date
        case chapterType
        case status
        case completedExerciseCount
        case exerciseCount
        case exerciseResults
        case stars
        case coinsEarned
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        childId = try container.decode(String.self, forKey: .childId)
        date = try container.decode(String.self, forKey: .date)
        chapterType = try container.decodeIfPresent(ChapterType.self, forKey: .chapterType) ?? .daily
        status = try container.decode(ChapterStatus.self, forKey: .status)
        exerciseResults = try container.decodeIfPresent([ExerciseResult].self, forKey: .exerciseResults) ?? []
        completedExerciseCount = try container.decodeIfPresent(Int.self, forKey: .completedExerciseCount) ?? exerciseResults.count
        // Chapters saved before short chapters existed were all 20 long
        exerciseCount = try container.decodeIfPresent(Int.self, forKey: .exerciseCount) ?? 20
        stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        coinsEarned = try container.decodeIfPresent(Int.self, forKey: .coinsEarned) ?? 0
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
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
        completedExerciseCount >= exerciseCount
    }

    /// Three in four answered right on the first try (15 of 20, 8 of 10).
    var isFastSolve: Bool {
        firstTryCount * 4 >= exerciseCount * 3
    }

    /// Conflict rule for sync: completed beats in-progress, then more answers wins.
    func isMoreProgressed(than other: ChapterProgress) -> Bool {
        if status != other.status { return status == .completed }
        if completedExerciseCount != other.completedExerciseCount {
            return completedExerciseCount > other.completedExerciseCount
        }
        return exerciseResults.count > other.exerciseResults.count
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
        if isFastSolve { coins += 10 }
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
