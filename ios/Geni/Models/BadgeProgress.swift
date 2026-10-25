import Foundation

/// How far a child is toward a badge, derived from the same counters `AppViewModel.checkBadges` tests.
nonisolated struct BadgeProgress: Equatable, Sendable {
    let current: Int
    let target: Int

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(max(Double(current) / Double(target), 0), 1)
    }

    var filled: Int { min(max(current, 0), target) }

    /// Targets this small read better as pips than as a bar.
    var usesPips: Bool { target <= 7 }
}

extension Badge {
    /// Reading and full-day badges: hidden while the child's reading mode is `.hidden`.
    var needsReading: Bool {
        ["first_reading", "reading_5", "reading_master", "full_chapter"].contains(id)
    }

    /// Counter-based progress. Event badges (perfect, fast_solver, mul_master, full_chapter)
    /// are single-chapter or single-day events with no counter, so they return nil.
    func progress(in rewards: RewardState) -> BadgeProgress? {
        switch id {
        case "first_chapter": return BadgeProgress(current: rewards.totalChaptersCompleted, target: 1)
        case "chapters_10": return BadgeProgress(current: rewards.totalChaptersCompleted, target: 10)
        case "streak_3": return BadgeProgress(current: rewards.streakCount, target: 3)
        case "streak_7": return BadgeProgress(current: rewards.streakCount, target: 7)
        case "streak_14": return BadgeProgress(current: rewards.streakCount, target: 14)
        case "streak_30": return BadgeProgress(current: rewards.streakCount, target: 30)
        case "correct_100": return BadgeProgress(current: rewards.totalCorrectAnswers, target: 100)
        case "first_reading": return BadgeProgress(current: rewards.totalReadingSessions, target: 1)
        case "reading_5": return BadgeProgress(current: rewards.totalReadingSessions, target: 5)
        case "reading_master": return BadgeProgress(current: rewards.totalReadingMinutes, target: 30)
        default: return nil
        }
    }

    func isEarned(in rewards: RewardState) -> Bool {
        rewards.badgesUnlocked.contains(id)
    }

    func ratio(in rewards: RewardState) -> Double {
        isEarned(in: rewards) ? 1 : (progress(in: rewards)?.ratio ?? 0)
    }

    /// Badges to show: everything, minus unearned reading badges when reading is hidden.
    static func visible(rewards: RewardState, readingMode: ReadingRequirement?) -> [Badge] {
        all.filter { badge in
            badge.isEarned(in: rewards) || !(badge.needsReading && readingMode == .hidden)
        }
    }

    /// Grid order: earned first in catalogue order, then locked by progress ratio (ties: catalogue order).
    static func sorted(rewards: RewardState, readingMode: ReadingRequirement?) -> [Badge] {
        let visible = visible(rewards: rewards, readingMode: readingMode)
        let earned = visible.filter { $0.isEarned(in: rewards) }
        let locked = visible.enumerated()
            .filter { !$0.element.isEarned(in: rewards) }
            .sorted { a, b in
                let ra = a.element.ratio(in: rewards), rb = b.element.ratio(in: rewards)
                return ra != rb ? ra > rb : a.offset < b.offset
            }
            .map(\.element)
        return earned + locked
    }

    /// The unearned eligible badge closest to done; First Steps (or the first unearned) when nothing has progress.
    /// Nil when every eligible badge is earned.
    static func nextGoal(rewards: RewardState, readingMode: ReadingRequirement?) -> Badge? {
        let candidates = visible(rewards: rewards, readingMode: readingMode)
            .filter { !$0.isEarned(in: rewards) }
        guard !candidates.isEmpty else { return nil }
        var best: (badge: Badge, ratio: Double)?
        for badge in candidates {
            let r = badge.ratio(in: rewards)
            if best == nil || r > best!.ratio { best = (badge, r) }
        }
        if let best, best.ratio > 0 { return best.badge }
        return candidates.first { $0.id == "first_chapter" } ?? candidates.first
    }
}

extension RewardState {
    /// Within-level XP as 0…1, safe against a zero denominator or out-of-range values.
    var xpFraction: Double {
        guard xpForNextLevel > 0 else { return 0 }
        return min(max(Double(xp) / Double(xpForNextLevel), 0), 1)
    }
}
