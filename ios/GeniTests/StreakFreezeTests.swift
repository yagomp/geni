import Foundation
import Testing
@testable import Geni

/// One missed day per Monday–Sunday week is covered by that week's streak freeze.
struct StreakFreezeTests {
    private func play(_ days: [String]) -> RewardState {
        var rewards = RewardState()
        for day in days { rewards.updateStreak(for: day) }
        return rewards
    }

    private func date(_ dateString: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: dateString)!
    }

    @Test func consecutiveDaysBuildTheStreakWithoutSpendingAFreeze() {
        let rewards = play(["2026-10-19", "2026-10-20", "2026-10-21"])
        #expect(rewards.streakCount == 3)
        #expect(rewards.streakFreezeWeek == nil)
    }

    @Test func oneMissedDayUsesThatWeeksFreeze() {
        var rewards = play(["2026-10-19"])
        rewards.updateStreak(for: "2026-10-21") // Tuesday missed
        #expect(rewards.streakCount == 2)
        #expect(rewards.streakFreezeWeek == "2026-10-19")
        #expect(!rewards.isStreakFreezeAvailable(on: date("2026-10-21")))
    }

    @Test func secondMissInTheSameWeekResets() {
        var rewards = play(["2026-10-19", "2026-10-21", "2026-10-22"]) // Tuesday missed, freeze spent
        #expect(rewards.streakCount == 3)
        rewards.updateStreak(for: "2026-10-24") // Friday missed, same week
        #expect(rewards.streakCount == 1)
        #expect(rewards.streakFreezeWeek == "2026-10-19")
        #expect(!rewards.isStreakFreezeAvailable(on: date("2026-10-24")))
    }

    @Test func newWeekGetsANewFreeze() {
        // The week of 19 Oct spends its freeze on Tuesday; the week of 26 Oct gets a fresh one.
        var rewards = play(["2026-10-19", "2026-10-21", "2026-10-22", "2026-10-23", "2026-10-24", "2026-10-25"])
        #expect(rewards.streakCount == 6)
        #expect(rewards.isStreakFreezeAvailable(on: date("2026-10-26")))
        rewards.updateStreak(for: "2026-10-27") // Monday 26 Oct missed
        #expect(rewards.streakCount == 7)
        #expect(rewards.streakFreezeWeek == "2026-10-26")
    }

    @Test func missedSundayBelongsToTheWeekItEndsWith() {
        // Sunday 18 Oct closes the week of 12 Oct, so Monday 19 Oct's week still has its freeze.
        var rewards = play(["2026-10-17"])
        rewards.updateStreak(for: "2026-10-19") // Sunday missed
        #expect(rewards.streakCount == 2)
        #expect(rewards.streakFreezeWeek == "2026-10-12")
        #expect(rewards.isStreakFreezeAvailable(on: date("2026-10-19")))
        rewards.updateStreak(for: "2026-10-21") // Tuesday 20 Oct missed, in the new week
        #expect(rewards.streakCount == 3)
        #expect(rewards.streakFreezeWeek == "2026-10-19")
    }

    @Test func twoMissedDaysInARowResetsWithoutSpendingAFreeze() {
        var rewards = play(["2026-10-19", "2026-10-20"])
        rewards.updateStreak(for: "2026-10-23") // Wednesday and Thursday missed
        #expect(rewards.streakCount == 1)
        #expect(rewards.streakFreezeWeek == nil)
    }

    @Test func savedRewardsWithoutTheFieldStillDecode() throws {
        let json = """
        {
          "coins": 40, "xp": 10, "level": 2, "streakCount": 4,
          "lastPlayedDate": "2026-10-19", "streakSaveAvailable": true,
          "badgesUnlocked": [], "cosmeticsUnlocked": [],
          "totalChaptersCompleted": 3, "totalCorrectAnswers": 9,
          "totalReadingSessions": 2, "totalReadingMinutes": 15,
          "todayMathCompleted": false, "todayReadingCompleted": false
        }
        """
        let rewards = try JSONDecoder().decode(RewardState.self, from: Data(json.utf8))
        #expect(rewards.streakCount == 4)
        #expect(rewards.lastPlayedDate == "2026-10-19")
        #expect(rewards.streakFreezeWeek == nil)
        #expect(rewards.isStreakFreezeAvailable(on: date("2026-10-21")))
    }

    @Test func mergeKeepsASpentFreezeFromEitherCopy() {
        let phone = play(["2026-10-19", "2026-10-21"]) // freeze spent on the phone
        let iPad = play(["2026-10-19", "2026-10-20"]) // nothing spent on the iPad
        #expect(phone.merged(with: iPad).streakFreezeWeek == "2026-10-19")
        #expect(iPad.merged(with: phone).streakFreezeWeek == "2026-10-19")
    }
}
