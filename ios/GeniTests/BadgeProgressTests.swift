import Foundation
import Testing
@testable import Geni

struct BadgeProgressTests {

    private func badge(_ id: String) -> Badge { Badge.all.first { $0.id == id }! }

    private func rewards(
        chapters: Int = 0, streak: Int = 0, correct: Int = 0,
        readings: Int = 0, minutes: Int = 0, earned: [String] = []
    ) -> RewardState {
        var r = RewardState()
        r.totalChaptersCompleted = chapters
        r.streakCount = streak
        r.totalCorrectAnswers = correct
        r.totalReadingSessions = readings
        r.totalReadingMinutes = minutes
        r.badgesUnlocked = earned
        return r
    }

    // MARK: - Progress vs. the real predicates (AppViewModel.checkBadges / checkReadingBadges)

    @Test func counterBadgesUseTheAwardThresholds() {
        let r = rewards(chapters: 4, streak: 5, correct: 62, readings: 3, minutes: 12)
        #expect(badge("first_chapter").progress(in: r) == BadgeProgress(current: 4, target: 1))
        #expect(badge("chapters_10").progress(in: r) == BadgeProgress(current: 4, target: 10))
        #expect(badge("streak_3").progress(in: r) == BadgeProgress(current: 5, target: 3))
        #expect(badge("streak_7").progress(in: r) == BadgeProgress(current: 5, target: 7))
        #expect(badge("streak_14").progress(in: r) == BadgeProgress(current: 5, target: 14))
        #expect(badge("streak_30").progress(in: r) == BadgeProgress(current: 5, target: 30))
        #expect(badge("correct_100").progress(in: r) == BadgeProgress(current: 62, target: 100))
        #expect(badge("first_reading").progress(in: r) == BadgeProgress(current: 3, target: 1))
        #expect(badge("reading_5").progress(in: r) == BadgeProgress(current: 3, target: 5))
        #expect(badge("reading_master").progress(in: r) == BadgeProgress(current: 12, target: 30))
    }

    @Test func ratioReachesOneExactlyWhenThePredicateHolds() {
        for (id, target, value): (String, Int, (inout RewardState, Int) -> Void) in [
            ("first_chapter", 1, { $0.totalChaptersCompleted = $1 }),
            ("chapters_10", 10, { $0.totalChaptersCompleted = $1 }),
            ("streak_3", 3, { $0.streakCount = $1 }),
            ("streak_7", 7, { $0.streakCount = $1 }),
            ("streak_14", 14, { $0.streakCount = $1 }),
            ("streak_30", 30, { $0.streakCount = $1 }),
            ("correct_100", 100, { $0.totalCorrectAnswers = $1 }),
            ("first_reading", 1, { $0.totalReadingSessions = $1 }),
            ("reading_5", 5, { $0.totalReadingSessions = $1 }),
            ("reading_master", 30, { $0.totalReadingMinutes = $1 }),
        ] {
            var below = RewardState()
            value(&below, target - 1)
            var at = RewardState()
            value(&at, target)
            #expect(badge(id).progress(in: below)!.ratio < 1, "\(id) below")
            #expect(badge(id).progress(in: at)!.ratio == 1, "\(id) at")
        }
    }

    @Test func progressClampsOvershoot() {
        let p = BadgeProgress(current: 250, target: 100)
        #expect(p.ratio == 1)
        #expect(p.filled == 100)
        #expect(BadgeProgress(current: -3, target: 5).ratio == 0)
    }

    @Test func eventBadgesNeverHavePartialProgress() {
        let r = rewards(chapters: 9, streak: 6, correct: 99, readings: 4, minutes: 29)
        for id in ["perfect_chapter", "fast_solver", "mul_master", "full_chapter"] {
            #expect(badge(id).progress(in: r) == nil, "\(id)")
            #expect(badge(id).ratio(in: r) == 0, "\(id)")
        }
    }

    @Test func pipsForSmallTargetsBarForLargeOnes() {
        #expect(BadgeProgress(current: 0, target: 7).usesPips)
        #expect(!BadgeProgress(current: 0, target: 10).usesPips)
    }

    @Test func earnedBadgeRatioIsOneEvenForEventBadges() {
        let r = rewards(earned: ["perfect_chapter"])
        #expect(badge("perfect_chapter").ratio(in: r) == 1)
    }

    // MARK: - Next goal

    @Test func newChildNextGoalIsFirstSteps() {
        #expect(Badge.nextGoal(rewards: RewardState(), readingMode: .required)?.id == "first_chapter")
    }

    @Test func nextGoalIsHighestRatio() {
        let r = rewards(chapters: 4, streak: 3, correct: 62, readings: 2, minutes: 12,
                        earned: ["first_chapter", "streak_3", "first_reading"])
        #expect(Badge.nextGoal(rewards: r, readingMode: .required)?.id == "correct_100")
    }

    @Test func nextGoalTiesFollowCatalogueOrder() {
        // chapters_10 (4/10), reading_5 (2/5) and reading_master (12/30) are all 0.4; streak_7 is 0 here.
        let r = rewards(chapters: 4, streak: 0, correct: 0, readings: 2, minutes: 12,
                        earned: ["first_chapter", "first_reading"])
        #expect(Badge.nextGoal(rewards: r, readingMode: .required)?.id == "chapters_10")
    }

    @Test func nextGoalFallsBackToFirstSteps() {
        // No counter has progress; First Steps is unearned.
        #expect(Badge.nextGoal(rewards: rewards(earned: ["streak_3"]), readingMode: .required)?.id == "first_chapter")
    }

    @Test func nextGoalFallsBackToFirstUnearnedWhenFirstStepsEarnedAndNoProgress() {
        let r = rewards(earned: ["first_chapter"])
        #expect(Badge.nextGoal(rewards: r, readingMode: .required)?.id == "streak_3")
    }

    @Test func nextGoalIsNilWhenEverythingEligibleIsEarned() {
        var r = rewards(earned: Badge.all.map(\.id))
        #expect(Badge.nextGoal(rewards: r, readingMode: .required) == nil)

        let nonReading = Badge.all.filter { !$0.needsReading }.map(\.id)
        r = rewards(earned: nonReading)
        #expect(Badge.nextGoal(rewards: r, readingMode: .hidden) == nil)
        #expect(Badge.nextGoal(rewards: r, readingMode: .optional) != nil)
    }

    @Test func hiddenReadingBadgesAreNeverTheNextGoal() {
        let r = rewards(chapters: 1, streak: 1, correct: 0, readings: 4, minutes: 10,
                        earned: ["first_chapter", "first_reading"])
        // reading_5 (4/5) would win if visible.
        #expect(Badge.nextGoal(rewards: r, readingMode: .required)?.id == "reading_5")
        #expect(Badge.nextGoal(rewards: r, readingMode: .hidden)?.id == "streak_3")
    }

    // MARK: - Visibility and order

    @Test func hiddenReadingModeDropsOnlyUnearnedReadingBadges() {
        let r = rewards(earned: ["first_reading"])
        let ids = Badge.visible(rewards: r, readingMode: .hidden).map(\.id)
        #expect(ids.contains("first_reading"))
        for id in ["reading_5", "reading_master", "full_chapter"] { #expect(!ids.contains(id), "\(id)") }
        #expect(Badge.visible(rewards: r, readingMode: .optional).count == Badge.all.count)
        #expect(Badge.visible(rewards: r, readingMode: .required).count == Badge.all.count)
    }

    @Test func sortedPutsEarnedFirstInCatalogueOrderThenByRatio() {
        let r = rewards(chapters: 4, streak: 3, correct: 62, readings: 2, minutes: 12,
                        earned: ["streak_3", "first_chapter", "perfect_chapter", "first_reading"])
        let ids = Badge.sorted(rewards: r, readingMode: .required).map(\.id)
        #expect(Array(ids.prefix(4)) == ["first_chapter", "streak_3", "perfect_chapter", "first_reading"])
        let locked = Array(ids.dropFirst(4))
        #expect(locked.first == "correct_100") // 0.62
        // ratio never increases down the locked list
        let ratios = locked.map { id in badge(id).ratio(in: r) }
        #expect(ratios == ratios.sorted(by: >))
        // ties keep catalogue order: chapters_10 (0.4) before reading_5 (0.4) before reading_master (0.4)
        let tied = ["chapters_10", "reading_5", "reading_master"].compactMap { locked.firstIndex(of: $0) }
        #expect(tied == tied.sorted())
        #expect(Set(ids).count == Badge.all.count)
    }

    @Test func badgeEmojiAreDistinct() {
        let emoji = Badge.all.map(\.emoji)
        #expect(Set(emoji).count == emoji.count)
    }

    // MARK: - XP fraction

    @Test func xpFractionClampsAndHandlesLevels() {
        var r = RewardState()
        #expect(r.xpFraction == 0)
        r.level = 3
        r.xp = 270
        #expect(abs(r.xpFraction - 0.45) < 0.0001)
        r.xp = 5_000
        #expect(r.xpFraction == 1)
        r.xp = -10
        #expect(r.xpFraction == 0)
        r.level = 0
        #expect(r.xpFraction == 0)
    }
}
