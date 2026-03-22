import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var showProfileCreation = false

    var body: some View {
        ZStack {
            switch viewModel.currentScreen {
            case .welcome:
                WelcomeView {
                    showProfileCreation = true
                }
                .transition(.opacity)

            case .onboarding:
                ProfileCreationView(onComplete: { profile in
                    viewModel.completeOnboarding(profile: profile)
                }, onBack: {
                    withAnimation { viewModel.currentScreen = .welcome }
                })
                .transition(.move(edge: .trailing))

            case .profilePicker:
                ProfilePickerView(
                    profiles: viewModel.persistence.profiles,
                    onSelect: { profile in
                        viewModel.selectProfile(profile)
                    },
                    onAddProfile: {
                        showProfileCreation = true
                    }
                )
                .transition(.opacity)

            case .childHome:
                ChildHomeView(viewModel: viewModel)
                    .transition(.opacity)

            case .exercise:
                if let chapterVM = viewModel.chapterViewModel {
                    ExerciseView(
                        chapterVM: chapterVM,
                        persistence: viewModel.persistence,
                        onComplete: { chapter in
                            viewModel.completeChapter(chapter)
                        },
                        onExit: {
                            viewModel.returnHome()
                        }
                    )
                    .transition(.move(edge: .trailing))
                }

            case .chapterComplete:
                if let chapterVM = viewModel.chapterViewModel,
                   let completed = chapterVM.completedChapter {
                    ChapterCompleteView(
                        chapter: completed,
                        rewards: viewModel.rewardState,
                        xpEarned: chapterVM.xpEarned,
                        onContinue: {
                            viewModel.returnHome()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .missionTransition:
                MissionTransitionView(
                    mathStars: viewModel.missionMathStars,
                    mathCoins: viewModel.missionMathCoins,
                    onContinue: {
                        viewModel.continueToMissionReading()
                    }
                )
                .transition(.scale.combined(with: .opacity))

            case .readingMode:
                if let profile = viewModel.persistence.activeProfile {
                    let today = viewModel.persistence.todayString()
                    let text = ReadingContentService.textForToday(profile: profile, date: today)
                    ReadingModeSelectionView(
                        profile: profile,
                        readingText: text,
                        onSelectMode: { mode in
                            viewModel.selectReadingMode(mode)
                        },
                        onBack: {
                            viewModel.returnHome()
                        }
                    )
                    .transition(.move(edge: .trailing))
                }

            case .reading:
                if let readingVM = viewModel.readingViewModel {
                    GuidedReadingView(
                        readingVM: readingVM,
                        onComplete: { session in
                            viewModel.completeReading(session)
                        },
                        onExit: {
                            viewModel.returnHome()
                        }
                    )
                    .transition(.move(edge: .trailing))
                }

            case .readingComplete:
                if let session = viewModel.completedReadingSession {
                    ReadingCompleteView(
                        session: session,
                        rewards: viewModel.rewardState,
                        bonusAwarded: viewModel.readingBonusAwarded,
                        bonusCoins: viewModel.readingBonusCoins,
                        onContinue: {
                            viewModel.returnHome()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .missionComplete:
                MissionCompleteView(
                    mathStars: viewModel.missionMathStars,
                    mathCoins: viewModel.missionMathCoins,
                    mathXP: viewModel.missionMathXP,
                    readingCoins: viewModel.missionReadingCoins,
                    bonusCoins: viewModel.missionBonusCoins,
                    rewards: viewModel.rewardState,
                    onContinue: {
                        viewModel.returnHome()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }

            if viewModel.showLevelUp {
                LevelUpOverlay(level: viewModel.levelUpLevel) {
                    viewModel.dismissLevelUp()
                }
                .transition(.opacity)
                .zIndex(100)
            }

            if viewModel.showBadgeUnlock, let badge = viewModel.unlockedBadge {
                BadgeUnlockOverlay(badge: badge) {
                    viewModel.dismissBadge()
                }
                .transition(.opacity)
                .zIndex(101)
            }
        }
        .animation(.spring(response: 0.4), value: viewModel.currentScreen)
        .animation(.spring(response: 0.4), value: viewModel.showLevelUp)
        .animation(.spring(response: 0.4), value: viewModel.showBadgeUnlock)
        .fullScreenCover(isPresented: $showProfileCreation) {
            ProfileCreationView(onComplete: { profile in
                viewModel.persistence.saveProfile(profile)
                if !viewModel.persistence.hasOnboarded {
                    viewModel.completeOnboarding(profile: profile)
                }
                showProfileCreation = false
            }, onBack: {
                showProfileCreation = false
            })
        }
        .sheet(isPresented: $viewModel.showParentSettings) {
            ParentDashboardView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showRewards) {
            RewardsView(rewards: viewModel.rewardState)
        }
    }
}
