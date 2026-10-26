import Foundation

nonisolated struct RewardState: Codable, Sendable {
    var coins: Int
    var xp: Int
    var level: Int
    var streakCount: Int
    var lastPlayedDate: String?
    /// Monday ("yyyy-MM-dd") of the Monday–Sunday week whose streak freeze has been spent.
    var streakFreezeWeek: String?
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

    // 1.2.0 requires streakSaveAvailable. Keep writing it alongside the weekly freeze
    // so an older device can decode (and merge) these rewards instead of pushing stale data.
    // Decoding remains synthesized: pre-freeze payloads simply have no streakFreezeWeek.
    private enum EncodingKeys: String, CodingKey {
        case coins, xp, level, streakCount, lastPlayedDate, streakFreezeWeek, streakSaveAvailable
        case badgesUnlocked, cosmeticsUnlocked, totalChaptersCompleted, totalCorrectAnswers
        case totalReadingSessions, totalReadingMinutes, todayMathCompleted, todayReadingCompleted
        case lastMathDate, lastReadingDate, dailyCompletedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(coins, forKey: .coins)
        try container.encode(xp, forKey: .xp)
        try container.encode(level, forKey: .level)
        try container.encode(streakCount, forKey: .streakCount)
        try container.encodeIfPresent(lastPlayedDate, forKey: .lastPlayedDate)
        try container.encodeIfPresent(streakFreezeWeek, forKey: .streakFreezeWeek)
        try container.encode(isStreakFreezeAvailable(), forKey: .streakSaveAvailable)
        try container.encode(badgesUnlocked, forKey: .badgesUnlocked)
        try container.encode(cosmeticsUnlocked, forKey: .cosmeticsUnlocked)
        try container.encode(totalChaptersCompleted, forKey: .totalChaptersCompleted)
        try container.encode(totalCorrectAnswers, forKey: .totalCorrectAnswers)
        try container.encode(totalReadingSessions, forKey: .totalReadingSessions)
        try container.encode(totalReadingMinutes, forKey: .totalReadingMinutes)
        try container.encode(todayMathCompleted, forKey: .todayMathCompleted)
        try container.encode(todayReadingCompleted, forKey: .todayReadingCompleted)
        try container.encodeIfPresent(lastMathDate, forKey: .lastMathDate)
        try container.encodeIfPresent(lastReadingDate, forKey: .lastReadingDate)
        try container.encodeIfPresent(dailyCompletedAt, forKey: .dailyCompletedAt)
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

    /// Combines two copies of the same child's rewards without going backwards:
    /// the more-progressed copy is the base, unlocks are unioned and lifetime totals never drop.
    func merged(with other: RewardState) -> RewardState {
        func progress(_ s: RewardState) -> (Int, Int, Int) {
            (s.totalChaptersCompleted + s.totalReadingSessions, s.level, s.xp)
        }
        var result = progress(other) > progress(self) ? other : self
        let fallback = progress(other) > progress(self) ? self : other
        result.badgesUnlocked += fallback.badgesUnlocked.filter { !result.badgesUnlocked.contains($0) }
        result.cosmeticsUnlocked += fallback.cosmeticsUnlocked.filter { !result.cosmeticsUnlocked.contains($0) }
        // Keep the latest spent freeze so a freeze used on one copy can't be spent again on the other.
        result.streakFreezeWeek = [streakFreezeWeek, other.streakFreezeWeek].compactMap { $0 }.max()
        result.totalChaptersCompleted = max(totalChaptersCompleted, other.totalChaptersCompleted)
        result.totalCorrectAnswers = max(totalCorrectAnswers, other.totalCorrectAnswers)
        result.totalReadingSessions = max(totalReadingSessions, other.totalReadingSessions)
        result.totalReadingMinutes = max(totalReadingMinutes, other.totalReadingMinutes)
        return result
    }

    /// Whether this Monday–Sunday week (of `date`) still has its streak freeze unspent.
    func isStreakFreezeAvailable(on date: Date = .now) -> Bool {
        streakFreezeWeek != Self.weekKey(for: date)
    }

    mutating func updateStreak(for dateString: String) {
        guard let lastDate = lastPlayedDate else {
            streakCount = 1
            lastPlayedDate = dateString
            return
        }

        if lastDate == dateString { return }

        let fmt = Self.dayFormatter()
        guard let last = fmt.date(from: lastDate),
              let current = fmt.date(from: dateString) else {
            streakCount = 1
            lastPlayedDate = dateString
            return
        }

        let daysBetween = Calendar.current.dateComponents([.day], from: last, to: current).day ?? 0

        if daysBetween == 1 {
            streakCount += 1
        } else if daysBetween == 2,
                  let missed = Calendar.current.date(byAdding: .day, value: 1, to: last),
                  Self.weekKey(for: missed) != streakFreezeWeek {
            // One missed day per week is covered by that week's freeze.
            streakCount += 1
            streakFreezeWeek = Self.weekKey(for: missed)
        } else if daysBetween > 1 {
            streakCount = 1
        }

        lastPlayedDate = dateString
    }

    private static func dayFormatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }

    /// The Monday ("yyyy-MM-dd") starting the Monday–Sunday week that contains `date`.
    private static func weekKey(for date: Date) -> String {
        // Gregorian weekday: 1 = Sunday … 7 = Saturday, so this is the number of days since Monday.
        let calendar = Calendar(identifier: .gregorian)
        let daysSinceMonday = (calendar.component(.weekday, from: date) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: date) ?? date
        return dayFormatter().string(from: monday)
    }
}
