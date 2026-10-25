import SwiftUI

#if DEBUG
/// Debug-only visual QA hook: `-designPreview <screen>` opens one screen with a seeded profile.
/// Store screens: onboarding1/2/3, storeHome, storeExercise, clockRead, clockSet,
/// storeMatch, guidedReading, storeRewards, storeBadge, parentDashboard.
/// Language: `-geni_app_language english|norwegian` plus `-AppleLanguages (en)|(nb)`.
/// QA: chapterComplete, missionTransition, missionComplete, readingMode, readingComplete,
/// countingObjects, visualAddition, compareGroups, numberBonds, diceAddition, visualSubtraction,
/// multiStep, numberSequence, areaPerimeter, fractionPick, longDivision, comparison, missingNumber.
/// Combine with `-uiTestReset` for a clean profile on every launch.
enum DesignPreview {
    /// A dedicated local store and inert cloud store keep screenshot seeds off iCloud.
    /// Normal DEBUG launches and every Release launch keep the production dependencies.
    @MainActor
    static func makeViewModel() -> AppViewModel {
        guard screen != nil else { return AppViewModel() }
        let suite = "com.yagomp.geni.designPreview"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let persistence = PersistenceService(defaults: defaults)
        persistence.parentPin = nil
        let sync = CloudSyncService(store: PreviewCloudStore(), defaults: defaults, isICloudAvailable: { false })
        sync.setSyncEnabled(false)
        return AppViewModel(persistence: persistence, cloudSync: sync)
    }

    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-designPreview"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// `onboarding1/2/3`: profile creation at that step (2 and 3 prefilled with a name).
    static var onboardingStep: Int? {
        guard let screen, screen.hasPrefix("onboarding"), let step = Int(screen.dropFirst("onboarding".count)),
              (1...3).contains(step) else { return nil }
        return step
    }

    /// `-designPreviewFrame 375x667`: renders the root in that size (iPhone SE checks).
    static var frameSize: CGSize? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-designPreviewFrame"), i + 1 < args.count else { return nil }
        let parts = args[i + 1].split(separator: "x").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        return CGSize(width: parts[0], height: parts[1])
    }

    @MainActor
    static func apply(to vm: AppViewModel) {
        guard let screen else { return }
        if onboardingStep != nil {
            vm.currentScreen = .onboarding
            return
        }
        if screen.hasPrefix("store") || ["clockRead", "clockSet", "guidedReading", "parentDashboard"].contains(screen) {
            applyStore(screen, to: vm)
            return
        }
        if screen.hasPrefix("home-") {
            applyHome(screen, to: vm)
            return
        }
        if screen == "rewards" || screen == "rewardsEmpty" {
            applyRewards(empty: screen == "rewardsEmpty", to: vm)
            return
        }
        let age: Int
        switch screen {
        case "solveTap": age = 9
        case "trueFalse", "evenOdd", "match": age = 7
        default: age = 5
        }
        let profile = ChildProfile(nickname: "Mia", age: age, avatarId: "lion")
        vm.completeOnboarding(profile: profile)

        let group = profile.ageGroup
        let exercise: (() -> Exercise)?
        switch screen {
        case "tenFrame":
            exercise = { ExerciseGenerator.generateEmojiExercise(format: .tenFrame, difficulty: .normal) }
        case "countingObjects", "visualAddition", "compareGroups":
            exercise = { ExerciseGenerator.generateEmojiExercise(format: ExerciseFormat(rawValue: screen)!, difficulty: .normal) }
        case "numberBonds", "diceAddition", "visualSubtraction":
            exercise = { ExerciseGenerator.generateMiddleExercise(format: ExerciseFormat(rawValue: screen)!, difficulty: .normal, ageGroup: .middle, ops: [.addition]) }
        case "multiStep", "numberSequence", "areaPerimeter", "fractionPick", "longDivision":
            exercise = { ExerciseGenerator.generateOlderExercise(format: ExerciseFormat(rawValue: screen)!, difficulty: .normal) }
        case "comparison", "missingNumber":
            exercise = { ExerciseGenerator.generateExercise(operation: .addition, difficulty: .normal, ageGroup: group, format: ExerciseFormat(rawValue: screen)!) }
        case "solve", "solveTap":
            exercise = { ExerciseGenerator.generateExercise(operation: .addition, difficulty: .normal, ageGroup: group) }
        case "trueFalse":
            exercise = { ExerciseGenerator.generateExercise(operation: .addition, difficulty: .normal, ageGroup: group, format: .trueFalse) }
        case "evenOdd":
            exercise = { ExerciseGenerator.generateMiddleExercise(format: .evenOddSort, difficulty: .normal, ageGroup: group, ops: [.addition]) }
        case "match":
            exercise = { ExerciseGenerator.generateMatchConnectExercise(difficulty: .normal, ageGroup: group, ops: [.addition]) }
        default:
            exercise = nil
        }

        if let exercise {
            let chapter = ChapterProgress(childId: profile.id, date: vm.persistence.todayString())
            vm.chapterViewModel = ChapterViewModel(profile: profile, chapter: chapter, exercises: (0..<20).map { _ in exercise() })
            vm.currentScreen = .exercise
        }

        switch screen {
        case "chapterComplete":
            let exercise = Exercise(operand1: 8, operand2: 5, operation: .addition, difficulty: .normal)
            var chapter = ChapterProgress(childId: profile.id, date: vm.persistence.todayString())
            chapter.completedExerciseCount = 20
            chapter.exerciseResults = (0..<20).map { _ in
                ExerciseResult(chapterId: chapter.id, exercise: exercise, firstCorrect: true, secondCorrect: nil, attempts: 1)
            }
            chapter.calculateRewards()
            chapter.status = .completed
            let chapterVM = ChapterViewModel(profile: profile, chapter: chapter, exercises: [])
            chapterVM.completedChapter = chapter
            chapterVM.xpEarned = 100
            vm.chapterViewModel = chapterVM
            vm.currentScreen = .chapterComplete
        case "missionTransition", "missionComplete":
            vm.missionMathStars = 5
            vm.missionMathCoins = 50
            vm.missionMathXP = 100
            vm.missionReadingCoins = 15
            vm.missionBonusCoins = 25
            vm.currentScreen = screen == "missionTransition" ? .missionTransition : .missionComplete
        case "readingMode":
            vm.currentScreen = .readingMode
        case "readingComplete":
            var session = ReadingSession(childId: profile.id, date: vm.persistence.todayString(), readingTextId: "preview", mode: .readToMe, targetTimeSeconds: 180)
            session.readingTimeSeconds = 180
            session.complete()
            vm.completedReadingSession = session
            vm.currentScreen = .readingComplete
        case "badge":
            vm.unlockedBadge = Badge.all.first
            vm.showBadgeUnlock = true
        case "levelUp":
            vm.levelUpLevel = 3
            vm.showLevelUp = true
        default:
            break
        }
    }

    @MainActor
    private static func applyStore(_ screen: String, to vm: AppViewModel) {
        let profile = ChildProfile(nickname: "Daniel", age: screen == "storeHome" ? 6 : 7, avatarId: "lion")
        vm.completeOnboarding(profile: profile)
        let today = vm.persistence.todayString()
        var rewards = RewardState()
        rewards.level = 3
        rewards.xp = 270
        rewards.coins = 420
        rewards.streakCount = 3
        rewards.lastPlayedDate = today
        rewards.totalChaptersCompleted = 12
        rewards.totalCorrectAnswers = 228
        rewards.totalReadingSessions = 8
        rewards.totalReadingMinutes = 40
        rewards.badgesUnlocked = ["first_chapter", "streak_3", "perfect_chapter", "chapters_10", "correct_100", "first_reading", "reading_5"]

        // Real exercise results make parent accuracy and recent-chapter rows meaningful.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let sum = Exercise(olderFormat: .solveResult, answer: 13, options: [11, 13, 14, 15], difficulty: .normal, op1: 8, op2: 5)
        for daysAgo in 1...12 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            var chapter = ChapterProgress(childId: profile.id, date: formatter.string(from: date))
            chapter.exerciseResults = (0..<20).map { i in
                ExerciseResult(chapterId: chapter.id, exercise: sum, firstCorrect: i < 19, secondCorrect: nil, attempts: i < 19 ? 1 : 3)
            }
            chapter.completedExerciseCount = 20
            chapter.calculateRewards()
            chapter.status = .completed
            chapter.completedAt = date
            vm.persistence.saveChapterProgress(chapter)
        }

        if screen == "storeHome" {
            var chapter = ChapterProgress(childId: profile.id, date: today)
            chapter.completedExerciseCount = 20
            chapter.status = .completed
            chapter.completedAt = Date().addingTimeInterval(-120)
            chapter.stars = 5
            chapter.coinsEarned = 50
            vm.persistence.saveChapterProgress(chapter)
            rewards.todayMathCompleted = true
            rewards.lastMathDate = today
            // Age six: optional reading remains the Today action while Challenges are open.
        }
        vm.rewardState = rewards
        vm.persistence.saveRewardState(rewards, for: profile.id)
        vm.currentScreen = .childHome

        switch screen {
        case "storeRewards": vm.showRewards = true
        case "storeBadge":
            vm.unlockedBadge = Badge.all.first { $0.id == "streak_3" }
            vm.showBadgeUnlock = true
        case "parentDashboard": vm.showParentSettings = true
        case "guidedReading":
            let text = ReadingText(
                id: "store-cat", titleEN: "The Little Cat", titleNO: "Den lille katten",
                titleES: "La gatita", titlePT: "A gatinha",
                contentEN: "The sun is up. A small cat sits on a red mat. The cat is soft and warm. It has big green eyes. A yellow bird sings in a tall tree. The cat looks up at the bird. The bird flies away. The cat yawns and goes back to sleep.",
                contentNO: "Solen er oppe. En liten katt sitter på en rød matte. Katten er myk og varm. Den har store grønne øyne. En gul fugl synger i et høyt tre. Katten ser opp på fuglen. Fuglen flyr av sted. Katten gjesper og sover videre.",
                contentES: "Ha salido el sol. Una gatita está sentada en una alfombra roja. Es suave y tiene ojos verdes. Un pájaro canta en un árbol. La gatita mira al pájaro. El pájaro se aleja volando. La gatita vuelve a dormirse.",
                contentPT: "O sol nasceu. Uma gatinha está sentada num tapete vermelho. É macia e tem olhos verdes. Um pássaro canta numa árvore. A gatinha olha para o pássaro. O pássaro voa para longe. A gatinha volta a dormir.", ageGroup: profile.ageGroup)
            let reading = ReadingViewModel(profile: profile, readingText: text, mode: .readToMe, date: today)
            reading.currentWordIndex = 16
            reading.elapsedSeconds = 68
            // start() returns immediately, preserving the highlighted word without audio/timers.
            reading.isPlaying = true
            vm.readingViewModel = reading
            vm.currentScreen = .reading
        case "storeExercise", "storeMatch", "clockRead", "clockSet":
            let exercise: Exercise
            switch screen {
            case "storeMatch":
                exercise = Exercise(matchLeft: ["3 + 2", "4 + 4", "6 + 1", "5 + 5"],
                                    matchRight: ["8", "10", "5", "7"], correctIndices: [2, 0, 3, 1], difficulty: .normal)
            case "clockRead", "clockSet":
                exercise = Exercise(clockFormat: screen == "clockRead" ? .clockRead : .clockSet,
                                    times: [ClockTime(hour: 3, minute: 30)], minuteStep: 30, difficulty: .normal)
            default: exercise = sum
            }
            var chapter = ChapterProgress(childId: profile.id, date: today)
            chapter.completedExerciseCount = 7
            chapter.exerciseResults = (0..<7).map { _ in
                ExerciseResult(chapterId: chapter.id, exercise: sum, firstCorrect: true, secondCorrect: nil, attempts: 1)
            }
            let chapterVM = ChapterViewModel(profile: profile, chapter: chapter, exercises: Array(repeating: exercise, count: 20), startIndex: 7)
            if screen == "storeMatch" { chapterVM.completedMatches = [MatchStroke(leftIndex: 0, rightIndex: 2)] }
            vm.chapterViewModel = chapterVM
            vm.currentScreen = .exercise
        default: break
        }
    }

    /// `rewards`: level 3, partial XP, five badges earned, correct_100 as next goal. `rewardsEmpty`: brand-new child.
    @MainActor
    private static func applyRewards(empty: Bool, to vm: AppViewModel) {
        let profile = ChildProfile(nickname: "Mia", age: empty ? 6 : 7, avatarId: "lion")
        vm.completeOnboarding(profile: profile)

        var rewards = RewardState()
        if !empty {
            rewards.level = 3
            rewards.xp = 270
            rewards.coins = 120
            rewards.streakCount = 3
            rewards.totalChaptersCompleted = 4
            rewards.totalCorrectAnswers = 62
            rewards.totalReadingSessions = 2
            rewards.totalReadingMinutes = 12
            rewards.badgesUnlocked = ["first_chapter", "streak_3", "perfect_chapter", "mul_master", "first_reading"]
        }
        vm.rewardState = rewards
        vm.persistence.saveRewardState(rewards, for: profile.id)
        vm.currentScreen = .childHome
        vm.showRewards = true
    }

    /// A–F from the Today matrix; extra variants exercise resume, expiry and early reading.
    /// Append `-rounded` to any home fixture to verify the per-profile corner preference.
    @MainActor
    private static func applyHome(_ requestedScreen: String, to vm: AppViewModel) {
        let rounded = requestedScreen.hasSuffix("-rounded")
        let screen = rounded ? String(requestedScreen.dropLast("-rounded".count)) : requestedScreen
        var profile = ChildProfile(nickname: "Ada", age: screen == "home-c" ? 8 : 6, avatarId: "lion")
        profile.cornerStyle = rounded ? .rounded : .sharp
        if screen.hasPrefix("home-f") { profile.readingEnabled = false }
        vm.completeOnboarding(profile: profile)

        let mathDone = ["home-c", "home-d", "home-d-open", "home-e", "home-e-closed", "home-f-done"].contains(screen)
        let inProgress = ["home-b", "home-b-final", "home-f-progress"].contains(screen)
        let closed = ["home-d", "home-e-closed", "home-f-done"].contains(screen)
        let completedAt = Date().addingTimeInterval(closed ? -660 : -120)

        if mathDone || inProgress {
            var chapter = ChapterProgress(childId: profile.id, date: vm.persistence.todayString())
            chapter.completedExerciseCount = mathDone || screen == "home-b-final" ? 20 : 7
            chapter.status = mathDone ? .completed : .inProgress
            chapter.completedAt = mathDone ? completedAt : nil
            vm.persistence.saveChapterProgress(chapter)
        }

        let readingDone = ["home-e", "home-e-closed", "home-a-reading-done"].contains(screen)
        if readingDone {
            var reading = ReadingSession(childId: profile.id, date: vm.persistence.todayString(),
                                         readingTextId: "design-preview", mode: .readToMe,
                                         targetTimeSeconds: ReadingText.targetReadingSeconds(for: profile.age))
            reading.complete()
            reading.completedAt = completedAt
            vm.persistence.saveReadingSession(reading)
        }

        var rewards = RewardState()
        rewards.coins = mathDone ? 50 : 0
        rewards.streakCount = mathDone ? 3 : 0
        rewards.todayMathCompleted = mathDone
        rewards.todayReadingCompleted = readingDone
        rewards.lastMathDate = mathDone ? vm.persistence.todayString() : nil
        rewards.lastReadingDate = readingDone ? vm.persistence.todayString() : nil
        rewards.dailyCompletedAt = mathDone && (profile.readingMode != .required || readingDone) ? completedAt : nil
        vm.rewardState = rewards
        vm.persistence.saveRewardState(rewards, for: profile.id)
        vm.currentScreen = .childHome
    }
}

/// No network or ubiquitous-store reads/writes for preview launches, including initialization.
private final class PreviewCloudStore: CloudKeyValueStore {
    func data(forKey key: String) -> Data? { nil }
    func set(_ data: Data?, forKey key: String) {}
    func double(forKey key: String) -> Double { 0 }
    func set(_ value: Double, forKey key: String) {}
    func bool(forKey key: String) -> Bool { false }
    func set(_ value: Bool, forKey key: String) {}
    func removeObject(forKey key: String) {}
    func synchronize() -> Bool { true }
}
/// `avatarSheet`: the avatar chooser over home. `-designPreviewFrame WxH`: SE-sized root
/// (a 20pt status-bar inset, centred and outlined).
private struct DesignPreviewModifier: ViewModifier {
    let viewModel: AppViewModel
    @State private var showAvatarSheet = false

    func body(content: Content) -> some View {
        framed(content)
            .task {
                DesignPreview.apply(to: viewModel)
                showAvatarSheet = DesignPreview.screen == "avatarSheet"
            }
            .sheet(isPresented: $showAvatarSheet) {
                AvatarChooserSheet(viewModel: viewModel)
            }
    }

    @ViewBuilder
    private func framed(_ content: Content) -> some View {
        if let size = DesignPreview.frameSize {
            content
                .safeAreaInset(edge: .top, spacing: 0) { Color.black.frame(height: 20) }
                .frame(width: size.width, height: size.height)
                .clipped()
                .overlay(Rectangle().stroke(Color.red, lineWidth: 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.ignoresSafeArea())
        } else {
            content
        }
    }
}
extension View {
    /// Show the actual dashboard scrolled to progress; no layout changes or PIN bypass in Release.
    func designPreviewParentScroll() -> some View {
        ScrollViewReader { proxy in
            self.task {
                guard DesignPreview.screen == "parentDashboard" else { return }
                try? await Task.sleep(for: .milliseconds(500))
                proxy.scrollTo("designPreview.parentProgress", anchor: .top)
            }
        }
    }

    /// Applies `-designPreview` and `-designPreviewFrame` (DEBUG only).
    func designPreview(_ viewModel: AppViewModel) -> some View {
        modifier(DesignPreviewModifier(viewModel: viewModel))
    }
}
#endif
