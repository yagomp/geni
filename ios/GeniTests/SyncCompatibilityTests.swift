import Foundation
import Testing
@testable import Geni

/// Wire models from 8f5d237 (1.2.0), without app behavior. Keep the shipped required keys
/// and ChapterProgress's defaulting decoder here so current-model changes cannot hide regressions.
private enum V120 {
    struct RewardState: Codable {
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
    }

    enum CornerStyle: String, Codable { case sharp, rounded }
    enum AppTheme: String, Codable { case standard, ocean, blossom }
    enum MathOperation: String, Codable { case addition, subtraction, multiplication, division }
    enum ExerciseDifficulty: Int, Codable { case warmup = 0, normal, harder, challenge }
    enum ChapterType: String, Codable { case daily, timeAttack, perfectRun, boss, streak, operationSpotlight }
    enum ChapterStatus: String, Codable { case inProgress, completed }
    enum ReadingMode: String, Codable { case readByMyself, readToMe, listenToMeRead }

    struct ChildProfile: Codable {
        let id: String
        var nickname: String
        var age: Int
        var avatarId: String
        var operationsEnabled: [MathOperation]
        var remindersEnabled: Bool
        var adaptiveDifficultyEnabled: Bool
        let createdAt: Date
        var theme: AppTheme
        var readingEnabled: Bool?
        var cornerStyle: CornerStyle?
    }

    struct ExerciseResult: Codable {
        let id: String
        let chapterId: String
        let prompt: String
        let operationType: MathOperation
        let difficulty: ExerciseDifficulty
        var firstAttemptCorrect: Bool
        var secondAttemptCorrect: Bool?
        var attemptsUsed: Int
        let answeredAt: Date
    }

    struct ChapterProgress: Codable {
        let id: String
        let childId: String
        let date: String
        var chapterType: ChapterType
        var status: ChapterStatus
        var completedExerciseCount: Int
        var exerciseResults: [ExerciseResult]
        var stars: Int
        var coinsEarned: Int
        var completedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case id, childId, date, chapterType, status, completedExerciseCount
            case exerciseResults, stars, coinsEarned, completedAt
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
            stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
            coinsEarned = try container.decodeIfPresent(Int.self, forKey: .coinsEarned) ?? 0
            completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        }
    }

    struct ReadingSession: Codable {
        let id: String
        let childId: String
        let date: String
        let readingTextId: String
        var mode: ReadingMode
        var readingTimeSeconds: Int
        var targetTimeSeconds: Int
        var isCompleted: Bool
        var coinsEarned: Int
        var completedAt: Date?
    }
}

@MainActor
struct SyncCompatibilityTests {
    // Cover local persistence's dates as well as CloudSyncService's ISO-8601 dates.
    @Test(arguments: [false, true])
    func currentPayloadsDecodeOn120AndResaveInto130(cloudDates: Bool) throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        if cloudDates {
            encoder.dateEncodingStrategy = .iso8601
            decoder.dateDecodingStrategy = .iso8601
        }
        var rewards = RewardState()
        rewards.coins = 123
        rewards.lastPlayedDate = "2026-10-26"
        rewards.dailyCompletedAt = Date(timeIntervalSince1970: 1_792_972_800)
        let oldRewards = try decoder.decode(V120.RewardState.self, from: encoder.encode(rewards))
        #expect(oldRewards.coins == 123)
        #expect(oldRewards.streakSaveAvailable)
        let restoredRewards = try decoder.decode(RewardState.self, from: encoder.encode(oldRewards))
        #expect(restoredRewards.coins == 123)
        #expect(restoredRewards.lastPlayedDate == rewards.lastPlayedDate)
        #expect(restoredRewards.dailyCompletedAt == rewards.dailyCompletedAt)
        #expect(restoredRewards.streakFreezeWeek == nil)
        rewards.streakFreezeWeek = "2026-10-26"
        let frozenData = try encoder.encode(rewards)
        let frozenLegacy = try decoder.decode(V120.RewardState.self, from: frozenData)
        #expect(frozenLegacy.streakSaveAvailable == rewards.isStreakFreezeAvailable())
        let frozenCurrent = try decoder.decode(RewardState.self, from: frozenData)
        #expect(frozenCurrent.streakFreezeWeek == rewards.streakFreezeWeek)

        var profile = ChildProfile(nickname: "Sync", age: 8, avatarId: "fox")
        profile.theme = .ocean
        profile.readingEnabled = false
        profile.focusGames = ["moneyPay"]
        var oldProfile = try decoder.decode(V120.ChildProfile.self, from: encoder.encode(profile))
        #expect(oldProfile.nickname == profile.nickname)
        #expect(oldProfile.operationsEnabled.map(\.rawValue) == profile.operationsEnabled.map(\.rawValue))
        oldProfile.cornerStyle = .rounded
        let restoredProfile = try decoder.decode(ChildProfile.self, from: encoder.encode(oldProfile))
        #expect(restoredProfile.id == profile.id)
        #expect(restoredProfile.theme == .ocean)
        #expect(restoredProfile.readingEnabled == false)
        #expect(restoredProfile.focusGames == nil)

        for type in ChapterType.allCompatibilityCases {
            var chapter = ChapterProgress(childId: profile.id, date: "2026-10-26", chapterType: type, exerciseCount: 10)
            let arithmetic = Exercise(operand1: 3, operand2: 2, operation: .multiplication, difficulty: .normal)
            let game = CodingGames.make(.codingPath, age: 7, difficulty: .warmup)
            chapter.exerciseResults = [arithmetic, game].map {
                ExerciseResult(chapterId: chapter.id, exercise: $0, firstCorrect: false, secondCorrect: true, attempts: 2)
            }
            chapter.completedExerciseCount = 2
            chapter.status = .completed
            chapter.completedAt = rewards.dailyCompletedAt
            chapter.calculateRewards()
            let oldChapter = try decoder.decode(V120.ChapterProgress.self, from: encoder.encode(chapter))
            #expect(oldChapter.exerciseResults.count == 2)
            #expect(oldChapter.chapterType.rawValue == type.rawValue)
            let restoredChapter = try decoder.decode(ChapterProgress.self, from: encoder.encode(oldChapter))
            #expect(restoredChapter.exerciseCount == 20)
            #expect(restoredChapter.exerciseResults.count == 2)
            #expect(restoredChapter.exerciseResults.allSatisfy { $0.wasCorrect })
            #expect(restoredChapter.completedAt == chapter.completedAt)
        }

        for mode in [ReadingMode.readByMyself, .readToMe, .listenToMeRead] {
            var session = ReadingSession(childId: profile.id, date: "2026-10-26", readingTextId: "t", mode: mode, targetTimeSeconds: 60)
            session.readingTimeSeconds = 75
            session.complete()
            let oldSession = try decoder.decode(V120.ReadingSession.self, from: encoder.encode(session))
            #expect(oldSession.readingTimeSeconds == 75)
            let restoredSession = try decoder.decode(ReadingSession.self, from: encoder.encode(oldSession))
            #expect(restoredSession.isCompleted)
            #expect(restoredSession.mode == mode)
            #expect(restoredSession.id == session.id)
        }
    }

    @Test func legacyUnavailableStreakSaveStillDecodes() throws {
        let old = V120.RewardState(coins: 42, xp: 50, level: 2, streakCount: 3,
                                  lastPlayedDate: "2026-10-26", streakSaveAvailable: false,
                                  badgesUnlocked: ["first_chapter"], cosmeticsUnlocked: [],
                                  totalChaptersCompleted: 2, totalCorrectAnswers: 30,
                                  totalReadingSessions: 1, totalReadingMinutes: 3,
                                  todayMathCompleted: true, todayReadingCompleted: false)
        let rewards = try JSONDecoder().decode(RewardState.self, from: JSONEncoder().encode(old))
        #expect(rewards.coins == 42)
        #expect(rewards.streakCount == 3)
        #expect(rewards.badgesUnlocked == ["first_chapter"])
    }

    @Test func legacyProfileResavePreservesFocusButExplicitClearSyncs() throws {
        let cloud = InMemoryCloudStore()
        let device = TestDevice(cloudStore: cloud)
        var profile = ChildProfile(nickname: "Focus", age: 8, avatarId: "fox")
        profile.focusGames = ["moneyPay"]
        device.persistence.saveProfile(profile)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var oldProfile = try decoder.decode(V120.ChildProfile.self, from: encoder.encode(profile))
        oldProfile.nickname = "Edited on 1.2.0"
        cloud.set(try encoder.encode([oldProfile]), forKey: "sync_profiles")
        device.cloud.pullFromCloud(persistence: device.persistence, force: true)
        #expect(device.persistence.activeProfile?.focusGames == ["moneyPay"])
        #expect(device.persistence.activeProfile?.nickname == oldProfile.nickname)
        device.cloud.pushToCloud(persistence: device.persistence)

        let second = TestDevice(cloudStore: cloud)
        second.cloud.pullFromCloud(persistence: second.persistence, force: true)
        #expect(second.persistence.activeProfile?.focusGames == ["moneyPay"])
        var cleared = try #require(second.persistence.activeProfile)
        cleared.focusGames = nil
        second.persistence.saveProfile(cleared)
        second.cloud.pushToCloud(persistence: second.persistence)
        device.cloud.pullFromCloud(persistence: device.persistence, force: true)
        #expect(device.persistence.activeProfile?.focusGames?.isEmpty == true)
    }
}

private extension ChapterType {
    static var allCompatibilityCases: [Self] { [.daily, .timeAttack, .perfectRun, .boss, .streak, .operationSpotlight] }
}
