import SwiftUI

#if DEBUG
/// Debug-only visual QA hook: `-designPreview <screen>` opens one screen with a seeded profile.
/// Screens: tenFrame, solve, solveTap, trueFalse, evenOdd, match, badge, levelUp, rewards, rewardsEmpty.
/// Combine with `-uiTestReset` for a clean profile on every launch.
enum DesignPreview {
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
    /// Applies `-designPreview` and `-designPreviewFrame` (DEBUG only).
    func designPreview(_ viewModel: AppViewModel) -> some View {
        modifier(DesignPreviewModifier(viewModel: viewModel))
    }
}
#endif
