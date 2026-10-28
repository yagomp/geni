//
//  ReadingAge6Tests.swift
//  GeniTests
//

import Foundation
import Testing
@testable import Geni

/// Daily mission routing per reading requirement: hidden (≤5), optional (6), required (7+).
@MainActor
struct ReadingAge6Tests {

    private func viewModel(_ device: TestDevice, age: Int) -> (AppViewModel, ChildProfile) {
        let profile = ChildProfile(nickname: "Kid", age: age, avatarId: "lion")
        let vm = device.makeViewModel()
        vm.completeOnboarding(profile: profile)
        return (vm, profile)
    }

    private func completeDailyMath(_ vm: AppViewModel, _ device: TestDevice, _ profile: ChildProfile) {
        vm.currentScreen = .exercise
        vm.completeChapter(ChapterProgress(childId: profile.id, date: device.persistence.todayString()))
    }

    private func todaysSession(_ device: TestDevice, _ profile: ChildProfile) -> ReadingSession {
        let text = ReadingContentService.textForToday(profile: profile, date: device.persistence.todayString(), history: [])
        return ReadingSession(
            childId: profile.id,
            date: device.persistence.todayString(),
            readingTextId: text.id,
            mode: .readToMe,
            targetTimeSeconds: ReadingText.targetReadingSeconds(for: profile.age)
        )
    }

    // MARK: - Age 6 (optional reading)

    @Test func age6DailyMathInvitesReadingAndCompletesDay() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 6)

        completeDailyMath(vm, device, profile)

        #expect(vm.currentScreen == .missionTransition)
        #expect(vm.isMissionFlow)
        #expect(vm.canFinishMissionWithoutReading)
        #expect(vm.todayFullChapterCompleted)
        #expect(vm.rewardState.dailyCompletedAt != nil)
        #expect(vm.challengeWindowStarted)
        #expect(device.persistence.loadRewardState(for: profile.id).dailyCompletedAt != nil)
    }

    @Test func age6FinishingWithoutReadingAwardsMathOnce() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 6)
        completeDailyMath(vm, device, profile)
        let coins = vm.rewardState.coins
        let completedAt = vm.rewardState.dailyCompletedAt

        vm.finishMissionWithoutReading()

        #expect(vm.currentScreen == .childHome)
        #expect(!vm.isMissionFlow)
        #expect(vm.todayFullChapterCompleted)
        #expect(!vm.todayReadingCompleted)
        #expect(vm.rewardState.coins == coins)
        #expect(vm.rewardState.totalChaptersCompleted == 1)
        #expect(vm.rewardState.dailyCompletedAt == completedAt)
        #expect(device.persistence.loadRewardState(for: profile.id).coins == coins)
    }

    @Test func age6ReadingInMissionRecordsReadingWithoutRewardingMathAgain() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 6)
        completeDailyMath(vm, device, profile)
        let mathCoins = vm.rewardState.coins
        let completedAt = vm.rewardState.dailyCompletedAt

        vm.continueToMissionReading()
        #expect(vm.currentScreen == .readingMode)
        vm.selectReadingMode(.readToMe)
        #expect(vm.currentScreen == .reading)
        #expect(vm.readingViewModel?.readingText.ageGroup == .young)

        vm.completeReading(todaysSession(device, profile))

        #expect(vm.currentScreen == .missionComplete)
        #expect(vm.todayReadingCompleted)
        #expect(vm.rewardState.totalReadingSessions == 1)
        #expect(vm.rewardState.totalChaptersCompleted == 1)
        #expect(vm.rewardState.coins == mathCoins + 15 + vm.missionBonusCoins)
        #expect(vm.missionBonusCoins == 15)
        // Reading must not restart the challenge window math opened
        #expect(vm.rewardState.dailyCompletedAt == completedAt)
        #expect(vm.rewardState.badgesUnlocked.contains("full_chapter"))
    }

    @Test func age6CanReadLaterFromHome() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 6)
        completeDailyMath(vm, device, profile)
        vm.finishMissionWithoutReading()
        let completedAt = vm.rewardState.dailyCompletedAt

        vm.startReading()
        #expect(vm.currentScreen == .readingMode)
        vm.completeReading(todaysSession(device, profile))

        #expect(vm.currentScreen == .readingComplete)
        #expect(vm.readingBonusAwarded)
        #expect(vm.todayReadingCompleted)
        #expect(vm.rewardState.dailyCompletedAt == completedAt)
    }

    @Test func age8ReadingBeforeMathCompletesDayWithBonus() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 8)

        vm.startReading()
        vm.completeReading(todaysSession(device, profile))
        #expect(vm.currentScreen == .readingComplete)
        #expect(!vm.readingBonusAwarded)
        #expect(vm.rewardState.dailyCompletedAt == nil)
        let coinsAfterReading = vm.rewardState.coins

        vm.startChapter()
        #expect(vm.chapterViewModel != nil)
        vm.completeChapter(ChapterProgress(childId: profile.id, date: device.persistence.todayString()))

        #expect(vm.currentScreen == .chapterComplete)
        #expect(vm.chapterViewModel?.bonusCoins == 15)
        #expect(vm.todayFullChapterCompleted)
        #expect(vm.rewardState.dailyCompletedAt != nil)
        let mathCoins = vm.chapterViewModel?.completedChapter?.coinsEarned
            ?? device.persistence.todayChapter(for: profile.id)?.coinsEarned ?? 0
        #expect(vm.rewardState.coins == coinsAfterReading + mathCoins + 15)
    }

    @Test func youngReadingUsesYoungTextsAndShortTarget() {
        let profile = ChildProfile(nickname: "Kid", age: 6, avatarId: "lion")
        let text = ReadingContentService.textForToday(profile: profile, date: "2099-01-01", history: [])
        #expect(text.ageGroup == .young)
        #expect(!text.words.isEmpty)
        #expect(ReadingText.targetReadingSeconds(for: 6) == 180)
    }

    // MARK: - Other ages unchanged

    @Test func age5DailyMathGoesStraightToChapterComplete() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 5)

        completeDailyMath(vm, device, profile)

        #expect(vm.currentScreen == .chapterComplete)
        #expect(!vm.isMissionFlow)
        #expect(!vm.canFinishMissionWithoutReading)
        #expect(vm.todayFullChapterCompleted)
        #expect(vm.rewardState.dailyCompletedAt != nil)
    }

    @Test func age7RequiresReadingToCompleteDay() {
        let device = TestDevice()
        let (vm, profile) = viewModel(device, age: 7)

        completeDailyMath(vm, device, profile)

        #expect(vm.currentScreen == .missionTransition)
        #expect(!vm.canFinishMissionWithoutReading)
        #expect(!vm.todayFullChapterCompleted)
        #expect(vm.rewardState.dailyCompletedAt == nil)

        vm.finishMissionWithoutReading()
        #expect(vm.currentScreen == .missionTransition)

        vm.continueToMissionReading()
        vm.completeReading(todaysSession(device, profile))

        #expect(vm.currentScreen == .missionComplete)
        #expect(vm.todayFullChapterCompleted)
        #expect(vm.rewardState.dailyCompletedAt != nil)
        #expect(vm.rewardState.totalChaptersCompleted == 1)
    }
}
