//
//  PersistenceSyncTests.swift
//  GeniTests
//

import Foundation
import Testing
@testable import Geni

/// In-memory stand-in for `NSUbiquitousKeyValueStore`, shared between simulated devices.
@MainActor
final class InMemoryCloudStore: CloudKeyValueStore {
    var values: [String: Any] = [:]

    func data(forKey aKey: String) -> Data? { values[aKey] as? Data }
    func set(_ aData: Data?, forKey aKey: String) { values[aKey] = aData }
    func double(forKey aKey: String) -> Double { values[aKey] as? Double ?? 0 }
    func set(_ value: Double, forKey aKey: String) { values[aKey] = value }
    func bool(forKey aKey: String) -> Bool { values[aKey] as? Bool ?? false }
    func set(_ value: Bool, forKey aKey: String) { values[aKey] = value }
    func removeObject(forKey aKey: String) { values.removeValue(forKey: aKey) }
    func synchronize() -> Bool { true }
}

/// One simulated device: its own defaults suite, optionally sharing a cloud store.
@MainActor
final class TestDevice {
    let suiteName = "geni.tests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let persistence: PersistenceService
    let cloud: CloudSyncService

    init(cloudStore: InMemoryCloudStore? = nil, seed: (PersistenceService) -> Void = { _ in }) {
        defaults = UserDefaults(suiteName: suiteName)!
        let seeding = PersistenceService(defaults: defaults)
        seed(seeding)
        persistence = PersistenceService(defaults: defaults)
        cloud = CloudSyncService(store: cloudStore ?? InMemoryCloudStore(), defaults: defaults, isICloudAvailable: { true })
    }

    func makeViewModel() -> AppViewModel {
        AppViewModel(persistence: persistence, cloudSync: cloud)
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }
}

@MainActor
struct PersistenceSyncTests {

    private func onboardedViewModel(_ device: TestDevice, profiles: [ChildProfile]) -> AppViewModel {
        let vm = device.makeViewModel()
        vm.completeOnboarding(profile: profiles[0])
        for profile in profiles.dropFirst() {
            vm.saveProfile(profile)
        }
        return vm
    }

    private func rewards(coins: Int, chapters: Int = 0) -> RewardState {
        var state = RewardState()
        state.coins = coins
        state.totalChaptersCompleted = chapters
        return state
    }

    // MARK: - Bug 1: deleting the active profile

    @Test func deletingActiveProfileKeepsOtherChildsRewards() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let b = ChildProfile(nickname: "B", age: 7, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [a, b])
        device.persistence.saveRewardState(rewards(coins: 10), for: a.id)
        device.persistence.saveRewardState(rewards(coins: 900), for: b.id)

        vm.selectProfile(b)
        vm.deleteProfile(b.id)

        #expect(device.persistence.activeProfileId == a.id)
        #expect(vm.rewardState.coins == 10)
        vm.selectProfile(a)
        #expect(device.persistence.loadRewardState(for: a.id).coins == 10)
    }

    @Test func switchingAfterDirectPersistenceDeleteDoesNotLeakRewards() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let b = ChildProfile(nickname: "B", age: 7, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [a, b])
        device.persistence.saveRewardState(rewards(coins: 10), for: a.id)
        device.persistence.saveRewardState(rewards(coins: 900), for: b.id)

        vm.selectProfile(b)
        device.persistence.deleteProfile(b.id)
        vm.selectProfile(a)

        #expect(device.persistence.loadRewardState(for: a.id).coins == 10)
        #expect(vm.rewardState.coins == 10)
    }

    // MARK: - Bug 2: resuming after the final answer

    @Test func resumingAfterFinalSavedAnswerShowsCompletion() {
        let device = TestDevice()
        let young = ChildProfile(nickname: "Resume", age: 6, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [young])
        var interrupted = ChapterProgress(childId: young.id, date: device.persistence.todayString())
        interrupted.completedExerciseCount = 20
        device.persistence.saveChapterProgress(interrupted)

        vm.startChapter()

        // Six-year-olds are invited to read after the daily chapter
        #expect(vm.currentScreen == .missionTransition)
        #expect(vm.chapterViewModel?.completedChapter?.id == interrupted.id)
        #expect(device.persistence.todayChapter(for: young.id)?.status == .completed)
    }

    // MARK: - Bug 5: incoming iCloud changes

    @Test func externalChangePullsCloudDataIntoRunningApp() {
        let cloud = InMemoryCloudStore()
        let deviceA = TestDevice(cloudStore: cloud)
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let vmA = onboardedViewModel(deviceA, profiles: [a])

        let deviceB = TestDevice(cloudStore: cloud)
        let vmB = deviceB.makeViewModel()
        #expect(deviceB.persistence.activeProfileId == a.id)

        var chapter = ChapterProgress(childId: a.id, date: "2026-01-01")
        chapter.status = .completed
        deviceA.persistence.saveChapterProgress(chapter)
        deviceA.persistence.saveRewardState(rewards(coins: 120, chapters: 1), for: a.id)
        deviceA.cloud.pushToCloud(persistence: deviceA.persistence)
        _ = vmA

        deviceB.cloud.onExternalChange?()

        #expect(deviceB.persistence.loadAllChapters(for: a.id).map(\.id) == [chapter.id])
        #expect(deviceB.persistence.loadRewardState(for: a.id).coins == 120)
        #expect(vmB.rewardState.coins == 120)
    }

    // MARK: - Bug 6: cloud snapshots merge instead of replacing

    @Test func cloudSnapshotKeepsUnsyncedLocalChapters() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        device.persistence.saveProfile(a)
        var local = ChapterProgress(childId: a.id, date: "2099-01-01")
        local.status = .completed
        device.persistence.saveChapterProgress(local)
        let remoteOnly = ChapterProgress(childId: a.id, date: "2099-01-02")

        device.persistence.applyCloudData(profiles: [a], chapters: [a.id: [remoteOnly]], rewards: [:], readings: [:], hasOnboarded: true)

        #expect(Set(device.persistence.loadAllChapters(for: a.id).map(\.id)) == [local.id, remoteOnly.id])
    }

    @Test func cloudSnapshotPrefersMoreProgressedChapter() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        device.persistence.saveProfile(a)
        var local = ChapterProgress(childId: a.id, date: "2099-01-01")
        local.completedExerciseCount = 12
        device.persistence.saveChapterProgress(local)
        var stale = local
        stale.completedExerciseCount = 3

        device.persistence.applyCloudData(profiles: [a], chapters: [a.id: [stale]], rewards: [:], readings: [:], hasOnboarded: true)
        #expect(device.persistence.loadAllChapters(for: a.id).first?.completedExerciseCount == 12)

        var finished = local
        finished.status = .completed
        device.persistence.applyCloudData(profiles: [a], chapters: [a.id: [finished]], rewards: [:], readings: [:], hasOnboarded: true)
        #expect(device.persistence.loadAllChapters(for: a.id).first?.status == .completed)
    }

    @Test func cloudSnapshotDoesNotMoveRewardsBackwards() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        device.persistence.saveProfile(a)
        var local = rewards(coins: 200, chapters: 5)
        local.badgesUnlocked = ["first_chapter"]
        device.persistence.saveRewardState(local, for: a.id)
        var remote = rewards(coins: 20, chapters: 1)
        remote.badgesUnlocked = ["first_reading"]

        device.persistence.applyCloudData(profiles: [a], chapters: [:], rewards: [a.id: remote], readings: [:], hasOnboarded: true)

        let merged = device.persistence.loadRewardState(for: a.id)
        #expect(merged.coins == 200)
        #expect(merged.totalChaptersCompleted == 5)
        #expect(Set(merged.badgesUnlocked) == ["first_chapter", "first_reading"])
    }

    @Test func cloudSnapshotKeepsUnsyncedReadings() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        device.persistence.saveProfile(a)
        var local = ReadingSession(childId: a.id, date: "2099-01-01", readingTextId: "t", mode: .readToMe, targetTimeSeconds: 60)
        local.complete()
        device.persistence.saveReadingSession(local)
        var staleCopy = local
        staleCopy.isCompleted = false

        device.persistence.applyCloudData(profiles: [a], chapters: [:], rewards: [:], readings: [a.id: [staleCopy]], hasOnboarded: true)

        #expect(device.persistence.loadAllReadingSessions(for: a.id).first?.isCompleted == true)
    }

    // MARK: - Bug 7: launch-time imports refresh cached rewards

    @Test func launchImportRefreshesCachedRewards() {
        let cloud = InMemoryCloudStore()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let deviceA = TestDevice(cloudStore: cloud)
        _ = onboardedViewModel(deviceA, profiles: [a])
        deviceA.persistence.saveRewardState(rewards(coins: 100, chapters: 4), for: a.id)
        deviceA.cloud.pushToCloud(persistence: deviceA.persistence)

        let deviceB = TestDevice(cloudStore: cloud) { local in
            local.saveProfile(a)
            local.completeOnboarding()
            var stale = RewardState()
            stale.coins = 10
            local.saveRewardState(stale, for: a.id)
        }
        let vmB = deviceB.makeViewModel()

        #expect(vmB.rewardState.coins == 100)
        vmB.selectProfile(a)
        #expect(deviceB.persistence.loadRewardState(for: a.id).coins == 100)
    }

    // MARK: - Bug 13: profile edits sync

    @Test func addingAndEditingProfilesPushesToCloud() throws {
        let cloud = InMemoryCloudStore()
        let device = TestDevice(cloudStore: cloud)
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [a])

        var b = ChildProfile(nickname: "B", age: 8, avatarId: "lion")
        vm.saveProfile(b)
        b.nickname = "Bee"
        vm.saveProfile(b)

        let data = try #require(cloud.data(forKey: "sync_profiles"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let synced = try decoder.decode([ChildProfile].self, from: data)
        #expect(synced.first { $0.id == b.id }?.nickname == "Bee")
    }

    // MARK: - Bug 14: deletions propagate

    @Test func deletedProfileIsNotRestoredByCloudSnapshot() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let b = ChildProfile(nickname: "B", age: 7, avatarId: "lion")
        device.persistence.saveProfile(a)
        device.persistence.saveProfile(b)

        device.persistence.deleteProfile(b.id)
        device.persistence.applyCloudData(profiles: [a, b], chapters: [b.id: [ChapterProgress(childId: b.id, date: "2099-01-01")]], rewards: [b.id: rewards(coins: 5)], readings: [:], hasOnboarded: true)

        #expect(!device.persistence.profiles.contains { $0.id == b.id })
        #expect(device.persistence.loadAllChapters(for: b.id).isEmpty)
        #expect(device.persistence.loadRewardState(for: b.id).coins == 0)
    }

    @Test func deletionPropagatesToOtherDevice() {
        let cloud = InMemoryCloudStore()
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let b = ChildProfile(nickname: "B", age: 7, avatarId: "lion")
        let deviceA = TestDevice(cloudStore: cloud)
        let vmA = onboardedViewModel(deviceA, profiles: [a, b])
        deviceA.persistence.saveRewardState(rewards(coins: 50), for: b.id)
        deviceA.cloud.pushToCloud(persistence: deviceA.persistence)

        let deviceB = TestDevice(cloudStore: cloud)
        let vmB = deviceB.makeViewModel()
        #expect(deviceB.persistence.profiles.contains { $0.id == b.id })

        vmA.deleteProfile(b.id)
        // Device B pushes before hearing about the deletion; the tombstone must survive
        deviceB.cloud.pushToCloud(persistence: deviceB.persistence)
        vmB.applyExternalCloudChange()
        vmA.applyExternalCloudChange()

        #expect(!deviceB.persistence.profiles.contains { $0.id == b.id })
        #expect(deviceB.persistence.loadRewardState(for: b.id).coins == 0)
        #expect(!deviceA.persistence.profiles.contains { $0.id == b.id })
    }

    // MARK: - Bug 15: topic progression syncs

    @Test func topicProgressSyncsAndMerges() {
        let cloud = InMemoryCloudStore()
        let a = ChildProfile(nickname: "A", age: 8, avatarId: "lion")
        let deviceA = TestDevice(cloudStore: cloud)
        _ = onboardedViewModel(deviceA, profiles: [a])
        var topics = TopicProgress()
        topics.addStars(9, for: .numbers)
        deviceA.persistence.saveTopicProgress(topics, for: a.id)
        deviceA.cloud.pushToCloud(persistence: deviceA.persistence)

        let deviceB = TestDevice(cloudStore: cloud) { local in
            local.saveProfile(a)
            var localTopics = TopicProgress()
            localTopics.addStars(3, for: .numbers)
            localTopics.addStars(2, for: MathTopic.allCases.last!)
            local.saveTopicProgress(localTopics, for: a.id)
        }
        let vmB = deviceB.makeViewModel()
        vmB.applyExternalCloudChange()

        let merged = deviceB.persistence.loadTopicProgress(for: a.id)
        #expect(merged.stars(for: .numbers) == 9)
        #expect(merged.stars(for: MathTopic.allCases.last!) == 2)
        #expect(vmB.topicProgress.stars(for: .numbers) == 9)
    }

    // MARK: - Bug 20: chapter completion is idempotent

    @Test func completingSameChapterTwiceAwardsOnce() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 5, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [a])
        let chapter = ChapterProgress(childId: a.id, date: device.persistence.todayString())
        vm.chapterViewModel = ChapterViewModel(profile: a, chapter: chapter, exercises: [])
        vm.currentScreen = .exercise

        vm.completeChapter(chapter)
        let coinsAfterFirst = vm.rewardState.coins
        vm.completeChapter(chapter)

        #expect(vm.rewardState.totalChaptersCompleted == 1)
        #expect(vm.rewardState.coins == coinsAfterFirst)
        #expect(device.persistence.loadRewardState(for: a.id).totalChaptersCompleted == 1)
        #expect(vm.currentScreen == .chapterComplete)
    }

    // MARK: - Bug 23: Multiply Master can be unlocked

    @Test func correctMultiplicationUnlocksMultiplyMaster() {
        let device = TestDevice()
        let a = ChildProfile(nickname: "A", age: 9, avatarId: "lion")
        let vm = onboardedViewModel(device, profiles: [a])
        var chapter = ChapterProgress(childId: a.id, date: "2099-01-01", chapterType: .timeAttack)
        let exercise = Exercise(operand1: 3, operand2: 4, operation: .multiplication, difficulty: .normal)
        chapter.exerciseResults = [ExerciseResult(chapterId: chapter.id, exercise: exercise, firstCorrect: true, secondCorrect: nil, attempts: 1)]
        chapter.completedExerciseCount = 1

        vm.completeChapter(chapter)

        #expect(vm.rewardState.badgesUnlocked.contains("mul_master"))
        #expect(Badge.all.contains { $0.id == "mul_master" })
    }
}
