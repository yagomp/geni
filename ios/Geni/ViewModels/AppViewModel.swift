import SwiftUI

@Observable
@MainActor
class AppViewModel {
    enum AppScreen: Equatable {
        case welcome
        case onboarding
        case profilePicker
        case childHome
        case exercise
        case chapterComplete
        case missionTransition
        case readingMode
        case reading
        case readingComplete
        case missionComplete
    }

    var currentScreen: AppScreen = .welcome
    var persistence: PersistenceService
    var rewardState: RewardState = RewardState()
    var chapterViewModel: ChapterViewModel?
    var readingViewModel: ReadingViewModel?
    var showParentSettings = false
    var showRewards = false
    var showBadges = false
    var cloudSync: CloudSyncService
    var notificationService: NotificationService
    var topicProgress: TopicProgress = TopicProgress()

    var showLevelUp = false
    var levelUpLevel: Int = 0
    var showBadgeUnlock = false
    var unlockedBadge: Badge? = nil
    var pendingBadges: [Badge] = []
    var isPremium: Bool = false

    static let challengeWindowSeconds: TimeInterval = 10 * 60

    var completedReadingSession: ReadingSession?
    var readingBonusAwarded: Bool = false
    var readingBonusCoins: Int = 0
    var isMissionFlow: Bool = false
    var missionMathCoins: Int = 0
    var missionMathStars: Int = 0
    var missionMathXP: Int = 0
    var missionReadingCoins: Int = 0
    var missionBonusCoins: Int = 0

    init() {
        self.persistence = PersistenceService()
        self.cloudSync = CloudSyncService()
        self.notificationService = NotificationService()
        self.isPremium = UserDefaults.standard.bool(forKey: "geni_is_premium")
        determineInitialScreen()

        // Pull cloud data on launch (handles new device scenario)
        cloudSync.pullFromCloud(persistence: persistence)
        if persistence.profiles.count > 0 && currentScreen == .welcome && persistence.hasOnboarded {
            determineInitialScreen()
        }

        // Handle incoming changes from other devices
        cloudSync.onExternalChange = { [weak self] in
            guard let self else { return }
            self.persistence.loadAll()
            if let profile = self.persistence.activeProfile {
                self.loadRewards(for: profile.id)
                self.refreshTodayStatus()
            }
        }
    }

    func determineInitialScreen() {
        if !persistence.hasOnboarded || persistence.profiles.isEmpty {
            currentScreen = .welcome
        } else if persistence.profiles.count > 1 && persistence.activeProfileId == nil {
            currentScreen = .profilePicker
        } else if let profile = persistence.activeProfile {
            loadRewards(for: profile.id)
            refreshTodayStatus()
            currentScreen = .childHome
        } else if let first = persistence.profiles.first {
            persistence.setActiveProfile(first.id)
            loadRewards(for: first.id)
            refreshTodayStatus()
            currentScreen = .childHome
        } else {
            currentScreen = .welcome
        }
    }

    func completeOnboarding(profile: ChildProfile) {
        persistence.saveProfile(profile)
        persistence.completeOnboarding()
        persistence.setActiveProfile(profile.id)
        loadRewards(for: profile.id)
        currentScreen = .childHome
        cloudSync.pushToCloud(persistence: persistence)
    }

    func selectProfile(_ profile: ChildProfile) {
        // Save current profile's rewards before switching
        if let currentId = persistence.activeProfileId {
            persistence.saveRewardState(rewardState, for: currentId)
        }
        persistence.setActiveProfile(profile.id)
        loadRewards(for: profile.id)
        refreshTodayStatus()
        currentScreen = .childHome
    }

    func startChapter(type: ChapterType = .daily, spotlightOp: MathOperation? = nil) {
        guard let profile = persistence.activeProfile else { return }
        let today = persistence.todayString()

        if type != .daily && challengeTimeExpired {
            return
        }

        if type == .daily {
            if let existing = persistence.todayChapter(for: profile.id), existing.status == .inProgress {
                let exercises: [Exercise]
                if profile.ageGroup == .middle || profile.ageGroup == .older {
                    exercises = ExerciseGenerator.generateTopicChapter(profile: profile, topic: topicProgress.currentTopic())
                } else {
                    exercises = ExerciseGenerator.generateChapter(profile: profile)
                }
                let startIndex = min(existing.exerciseResults.count, exercises.count)
                if startIndex >= exercises.count {
                    completeChapter(existing)
                    return
                }
                chapterViewModel = ChapterViewModel(
                    profile: profile,
                    chapter: existing,
                    exercises: exercises,
                    startIndex: startIndex
                )
            } else if persistence.todayChapter(for: profile.id) == nil {
                let chapter = ChapterProgress(childId: profile.id, date: today)
                let exercises: [Exercise]
                if profile.ageGroup == .middle || profile.ageGroup == .older {
                    exercises = ExerciseGenerator.generateTopicChapter(profile: profile, topic: topicProgress.currentTopic())
                } else {
                    exercises = ExerciseGenerator.generateChapter(profile: profile)
                }
                chapterViewModel = ChapterViewModel(profile: profile, chapter: chapter, exercises: exercises)
            } else {
                return
            }
        } else {
            let chapter = ChapterProgress(childId: profile.id, date: today, chapterType: type)
            let exercises: [Exercise]

            switch type {
            case .operationSpotlight:
                if let op = spotlightOp {
                    exercises = ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: op)
                } else {
                    exercises = ExerciseGenerator.generateChapter(profile: profile, chapterType: type)
                }
            default:
                exercises = ExerciseGenerator.generateChapter(profile: profile, chapterType: type)
            }

            chapterViewModel = ChapterViewModel(profile: profile, chapter: chapter, exercises: exercises)
        }

        if type != .daily {
            HapticManager.specialChapter()
        } else {
            HapticManager.chapterStart()
        }

        currentScreen = .exercise
    }

    func completeChapter(_ chapter: ChapterProgress) {
        guard let profile = persistence.activeProfile else { return }

        var final = chapter
        final.status = .completed
        final.completedAt = Date()
        final.calculateRewards()

        persistence.saveChapterProgress(final)

        let previousLevel = rewardState.level

        rewardState.coins += final.coinsEarned
        rewardState.totalChaptersCompleted += 1
        rewardState.totalCorrectAnswers += final.correctCount

        if final.chapterType == .daily {
            rewardState.todayMathCompleted = true
            rewardState.lastMathDate = persistence.todayString()
            if rewardState.todayReadingCompleted {
                rewardState.dailyCompletedAt = Date()
            }
        }

        var xpGain = 100
        if final.stars >= 4 { xpGain += 50 }
        if final.firstTryCount >= 15 { xpGain += 20 }
        if final.chapterType != .daily { xpGain += 50 }
        rewardState.addXP(xpGain)
        rewardState.updateStreak(for: persistence.todayString())

        // Track topic progress for middle age group
        if (profile.ageGroup == .middle || profile.ageGroup == .older) && final.chapterType == .daily {
            let currentTopic = topicProgress.currentTopic()
            topicProgress.addStars(final.stars, for: currentTopic)
            persistence.saveTopicProgress(topicProgress, for: profile.id)
        }

        let newBadges = checkBadges(chapter: final)
        persistence.saveRewardState(rewardState, for: profile.id)

        chapterViewModel?.completedChapter = final
        chapterViewModel?.xpEarned = xpGain

        if rewardState.level > previousLevel {
            levelUpLevel = rewardState.level
            showLevelUp = true
            HapticManager.levelUp()
        }

        pendingBadges = newBadges
        if !newBadges.isEmpty && !showLevelUp {
            showNextBadge()
        }

        HapticManager.coinReward()

        if final.chapterType == .daily && !rewardState.todayReadingCompleted {
            isMissionFlow = true
            missionMathCoins = final.coinsEarned
            missionMathStars = final.stars
            missionMathXP = xpGain
            currentScreen = .missionTransition
        } else {
            currentScreen = .chapterComplete
        }

        cloudSync.pushToCloud(persistence: persistence)
    }

    func startReading() {
        guard let profile = persistence.activeProfile else { return }
        let today = persistence.todayString()
        let text = ReadingContentService.textForToday(profile: profile, date: today)
        currentScreen = .readingMode
        readingViewModel = nil
        completedReadingSession = nil
        readingBonusAwarded = false
        readingBonusCoins = 0

        _ = text
    }

    func selectReadingMode(_ mode: ReadingMode) {
        guard let profile = persistence.activeProfile else { return }
        let today = persistence.todayString()
        let text = ReadingContentService.textForToday(profile: profile, date: today)
        readingViewModel = ReadingViewModel(profile: profile, readingText: text, mode: mode, date: today)
        HapticManager.chapterStart()
        currentScreen = .reading
    }

    func completeReading(_ session: ReadingSession) {
        guard let profile = persistence.activeProfile else { return }

        var final = session
        if !final.isCompleted {
            final.complete()
        }
        persistence.saveReadingSession(final)

        let previousLevel = rewardState.level

        rewardState.coins += final.coinsEarned
        rewardState.totalReadingSessions += 1
        rewardState.totalReadingMinutes += max(1, final.readingTimeSeconds / 60)
        rewardState.todayReadingCompleted = true
        rewardState.lastReadingDate = persistence.todayString()
        if rewardState.todayMathCompleted {
            rewardState.dailyCompletedAt = Date()
        }

        var xpGain = 50
        rewardState.addXP(xpGain)

        var bonusAwarded = false
        var bonusCoins = 0
        if rewardState.todayMathCompleted && rewardState.lastMathDate == persistence.todayString() {
            bonusCoins = 15
            rewardState.coins += bonusCoins
            rewardState.addXP(30)
            bonusAwarded = true
        }

        let newBadges = checkReadingBadges()
        persistence.saveRewardState(rewardState, for: profile.id)

        completedReadingSession = final
        readingBonusAwarded = bonusAwarded
        readingBonusCoins = bonusCoins
        missionReadingCoins = final.coinsEarned
        missionBonusCoins = bonusCoins

        if rewardState.level > previousLevel {
            levelUpLevel = rewardState.level
            showLevelUp = true
            HapticManager.levelUp()
        }

        pendingBadges.append(contentsOf: newBadges)
        if !pendingBadges.isEmpty && !showLevelUp {
            showNextBadge()
        }

        HapticManager.coinReward()

        if isMissionFlow {
            currentScreen = .missionComplete
        } else {
            currentScreen = .readingComplete
        }

        cloudSync.pushToCloud(persistence: persistence)
    }

    func dismissLevelUp() {
        showLevelUp = false
        if !pendingBadges.isEmpty {
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                showNextBadge()
            }
        }
    }

    func dismissBadge() {
        showBadgeUnlock = false
        unlockedBadge = nil
        if !pendingBadges.isEmpty {
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                showNextBadge()
            }
        }
    }

    private func showNextBadge() {
        guard !pendingBadges.isEmpty else { return }
        unlockedBadge = pendingBadges.removeFirst()
        showBadgeUnlock = true
        HapticManager.badgeUnlock()
    }

    func returnHome() {
        chapterViewModel = nil
        readingViewModel = nil
        completedReadingSession = nil
        isMissionFlow = false
        missionMathCoins = 0
        missionMathStars = 0
        missionMathXP = 0
        missionReadingCoins = 0
        missionBonusCoins = 0
        refreshTodayStatus()
        currentScreen = .childHome
    }

    func continueToMissionReading() {
        guard let profile = persistence.activeProfile else { return }
        let today = persistence.todayString()
        let text = ReadingContentService.textForToday(profile: profile, date: today)
        readingViewModel = nil
        completedReadingSession = nil
        currentScreen = .readingMode
        _ = text
    }

    func switchProfile() {
        currentScreen = .profilePicker
    }

    func updateAvatar(_ avatarId: String) {
        guard var profile = persistence.activeProfile else { return }
        profile.avatarId = avatarId
        persistence.saveProfile(profile)
        cloudSync.pushToCloud(persistence: persistence)
    }

    var todayMathCompleted: Bool {
        guard let profile = persistence.activeProfile else { return false }
        let chapter = persistence.todayChapter(for: profile.id)
        return chapter?.status == .completed
    }

    var todayChapterCompleted: Bool {
        todayMathCompleted
    }

    var todayReadingCompleted: Bool {
        guard let profile = persistence.activeProfile else { return false }
        return persistence.todayReadingSession(for: profile.id) != nil
    }

    var todayFullChapterCompleted: Bool {
        todayMathCompleted && todayReadingCompleted
    }

    var todayChapterInProgress: Bool {
        guard let profile = persistence.activeProfile else { return false }
        let chapter = persistence.todayChapter(for: profile.id)
        return chapter?.status == .inProgress
    }

    var todayChapterExercisesCompleted: Int {
        guard let profile = persistence.activeProfile else { return 0 }
        return persistence.todayChapter(for: profile.id)?.exerciseResults.count ?? 0
    }

    var completedChapterCount: Int {
        guard let profile = persistence.activeProfile else { return 0 }
        return persistence.loadAllChapters(for: profile.id).filter { $0.status == .completed }.count
    }

    var currentMathTopic: MathTopic {
        topicProgress.currentTopic()
    }

    var currentTopicStars: Int {
        topicProgress.stars(for: currentMathTopic)
    }

    var nextTopicThreshold: Int {
        currentMathTopic.next?.starsToUnlock ?? 0
    }

    var specialChapterAvailable: ChapterType? {
        guard let profile = persistence.activeProfile else { return nil }
        let completed = persistence.loadAllChapters(for: profile.id).filter { $0.status == .completed }
        let dailyCompleted = completed.filter { $0.chapterType == .daily }.count

        if dailyCompleted > 0 && dailyCompleted % 5 == 0 {
            let hasBossToday = completed.contains { $0.date == persistence.todayString() && $0.chapterType == .boss }
            if !hasBossToday { return .boss }
        }

        if rewardState.streakCount >= 3 {
            let hasStreakToday = completed.contains { $0.date == persistence.todayString() && $0.chapterType == .streak }
            if !hasStreakToday { return .streak }
        }

        return nil
    }

    var canStartTimeAttack: Bool {
        guard let profile = persistence.activeProfile else { return false }
        return profile.ageGroup != .young
    }

    var challengeTimeExpired: Bool {
        guard let completedAt = rewardState.dailyCompletedAt else { return false }
        return Date().timeIntervalSince(completedAt) >= Self.challengeWindowSeconds
    }

    func challengeSecondsRemaining() -> Int {
        guard let completedAt = rewardState.dailyCompletedAt else { return Int(Self.challengeWindowSeconds) }
        let elapsed = Date().timeIntervalSince(completedAt)
        return max(0, Int(Self.challengeWindowSeconds - elapsed))
    }

    private func loadRewards(for childId: String) {
        rewardState = persistence.loadRewardState(for: childId)
        topicProgress = persistence.loadTopicProgress(for: childId)
    }

    private func refreshTodayStatus() {
        let today = persistence.todayString()
        if rewardState.lastMathDate != today {
            rewardState.todayMathCompleted = false
            rewardState.dailyCompletedAt = nil
        }
        if rewardState.lastReadingDate != today {
            rewardState.todayReadingCompleted = false
            rewardState.dailyCompletedAt = nil
        }
        if let profile = persistence.activeProfile {
            if persistence.todayChapter(for: profile.id)?.status == .completed {
                rewardState.todayMathCompleted = true
                rewardState.lastMathDate = today
            }
            if persistence.todayReadingSession(for: profile.id) != nil {
                rewardState.todayReadingCompleted = true
                rewardState.lastReadingDate = today
            }
        }
    }

    private func checkBadges(chapter: ChapterProgress) -> [Badge] {
        var newBadges: [Badge] = []

        func tryAdd(_ id: String) {
            if !rewardState.badgesUnlocked.contains(id) {
                rewardState.badgesUnlocked.append(id)
                if let badge = Badge.all.first(where: { $0.id == id }) {
                    newBadges.append(badge)
                }
            }
        }

        if rewardState.totalChaptersCompleted >= 1 { tryAdd("first_chapter") }
        if rewardState.streakCount >= 3 { tryAdd("streak_3") }
        if rewardState.streakCount >= 7 { tryAdd("streak_7") }
        if rewardState.streakCount >= 14 { tryAdd("streak_14") }
        if rewardState.streakCount >= 30 { tryAdd("streak_30") }
        if rewardState.totalChaptersCompleted >= 10 { tryAdd("chapters_10") }
        if rewardState.totalCorrectAnswers >= 100 { tryAdd("correct_100") }
        if chapter.stars == 5 { tryAdd("perfect_chapter") }
        if chapter.firstTryCount >= 15 { tryAdd("fast_solver") }

        if rewardState.todayMathCompleted && rewardState.todayReadingCompleted {
            tryAdd("full_chapter")
        }

        return newBadges
    }

    private func checkReadingBadges() -> [Badge] {
        var newBadges: [Badge] = []

        func tryAdd(_ id: String) {
            if !rewardState.badgesUnlocked.contains(id) {
                rewardState.badgesUnlocked.append(id)
                if let badge = Badge.all.first(where: { $0.id == id }) {
                    newBadges.append(badge)
                }
            }
        }

        if rewardState.totalReadingSessions >= 1 { tryAdd("first_reading") }
        if rewardState.totalReadingSessions >= 5 { tryAdd("reading_5") }
        if rewardState.totalReadingMinutes >= 30 { tryAdd("reading_master") }

        if rewardState.todayMathCompleted && rewardState.todayReadingCompleted {
            tryAdd("full_chapter")
        }

        return newBadges
    }

    func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "geni_is_premium")
    }
}
