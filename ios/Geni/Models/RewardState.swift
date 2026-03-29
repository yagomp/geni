import Foundation

nonisolated struct RewardState: Codable, Sendable {
    var coins: Int
    var xp: Int
    var level: Int
    var streakCount: Int
    var lastPlayedDate: String?
    var streakSaveAvailable: Bool
    var badgesUnlocked: [String]
    var cosmeticsUnlocked: [String]
    var totalChaptersCompleted: Int
    var totalCorrectAnswers: Int
    var totalReadingSessions: Int
    var totalReadingMinutes: Int
    var todayMathCompleted: Bool
    var todayReadingCompleted: Bool
    var lastMathDate: String?
    var lastReadingDate: String?
    var dailyCompletedAt: Date?

    init() {
        self.coins = 0
        self.xp = 0
        self.level = 1
        self.streakCount = 0
        self.streakSaveAvailable = true
        self.badgesUnlocked = []
        self.cosmeticsUnlocked = []
        self.totalChaptersCompleted = 0
        self.totalCorrectAnswers = 0
        self.totalReadingSessions = 0
        self.totalReadingMinutes = 0
        self.todayMathCompleted = false
        self.todayReadingCompleted = false
        self.dailyCompletedAt = nil
    }

    var xpForNextLevel: Int {
        level * 200
    }

    var xpProgress: Double {
        Double(xp) / Double(xpForNextLevel)
    }

    mutating func addXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
        }
    }

    mutating func updateStreak(for dateString: String) {
        guard let lastDate = lastPlayedDate else {
            streakCount = 1
            lastPlayedDate = dateString
            return
        }

        if lastDate == dateString { return }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let last = fmt.date(from: lastDate),
              let current = fmt.date(from: dateString) else {
            streakCount = 1
            lastPlayedDate = dateString
            return
        }

        let daysBetween = Calendar.current.dateComponents([.day], from: last, to: current).day ?? 0

        if daysBetween == 1 {
            streakCount += 1
        } else if daysBetween == 2 && streakSaveAvailable {
            streakCount += 1
            streakSaveAvailable = false
        } else if daysBetween > 1 {
            streakCount = 1
            streakSaveAvailable = true
        }

        lastPlayedDate = dateString
    }
}
