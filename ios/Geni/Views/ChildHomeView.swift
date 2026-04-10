import SwiftUI

struct ChildHomeView: View {
    let viewModel: AppViewModel
    let rewardsNamespace: Namespace.ID
    let settingsNamespace: Namespace.ID
    @State private var showAvatarPicker = false
    @State private var showProfileCreation = false

    private var hasMultipleProfiles: Bool {
        viewModel.persistence.profiles.count > 1
    }

    var body: some View {
        let profile = viewModel.persistence.activeProfile
        let avatar = AvatarOption.find(profile?.avatarId ?? "lion")
        let rewards = viewModel.rewardState

        GeometryReader { geo in
            ZStack {
                GeniColor.lightYellow.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection(profile: profile, avatar: avatar, rewards: rewards)
                    Spacer()
                    statsRow(rewards: rewards)
                    Spacer()
                    missionCard
                    Spacer()
                    specialModesSection
                    Spacer().frame(height: iPadScale.isIPad ? 20 : 12)
                }
                .padding(.horizontal, iPadScale.padding)
                .padding(.top, iPadScale.isIPad ? 20 : 8)
                .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 0 : 12)
                .foregroundStyle(.black)
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showProfileCreation) {
            ProfileCreationView(onComplete: { profile in
                viewModel.persistence.saveProfile(profile)
                viewModel.selectProfile(profile)
                showProfileCreation = false
            }, onBack: {
                showProfileCreation = false
            })
        }
    }

    private func headerSection(profile: ChildProfile?, avatar: AvatarOption, rewards: RewardState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Emoji box — tappable only in single-profile mode
            let emojiBox = Text(avatar.emoji)
                .font(.system(size: 38))
                .frame(width: 68, height: 68)
                .background(.white)
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))

            if hasMultipleProfiles {
                emojiBox
            } else {
                Button {
                    HapticManager.selection()
                    showAvatarPicker = true
                } label: {
                    emojiBox
                }
            }

            // Name + level + siblings + settings all in one row, top-aligned
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile?.nickname ?? "")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text("\(L.s(.level)) \(rewards.level)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                }

                Spacer()

                // Siblings — wide gap from name, tight spacing between each other
                if hasMultipleProfiles {
                    HStack(spacing: 10) {
                        ForEach(viewModel.persistence.profiles.filter { $0.id != viewModel.persistence.activeProfileId }) { p in
                            let pAvatar = AvatarOption.find(p.avatarId)
                            Button {
                                HapticManager.impact(.medium)
                                viewModel.selectProfile(p)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(pAvatar.emoji)
                                        .font(.system(size: 20))
                                        .frame(width: 42, height: 42)
                                        .background(.white)
                                        .overlay(
                                            Rectangle()
                                                .stroke(GeniColor.border, lineWidth: 2)
                                        )
                                        .background(
                                            Rectangle()
                                                .fill(GeniColor.border)
                                                .offset(x: 2, y: 2)
                                        )

                                    Text(p.nickname)
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .foregroundStyle(GeniColor.border)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .frame(width: 42)
                                }
                            }
                        }
                    }
                    .padding(.trailing, 12)
                }

                // Settings — same row, same top alignment as text and siblings
                Button {
                    HapticManager.selection()
                    viewModel.showParentSettings = true
                } label: {
                    Text("⚙️")
                        .font(.system(size: 30))
                        .frame(width: 42, height: 42)
                        .zoomSource(id: "settings", in: settingsNamespace)
                }
            }
        }
    }

    private func statsRow(rewards: RewardState) -> some View {
        HStack(spacing: 8) {
            StatBubble(
                emoji: "🔥",
                value: "\(rewards.streakCount)",
                label: rewards.streakCount == 1 ? L.s(.day) : L.s(.days),
                sublabel: L.s(.streak),
                color: GeniColor.orange
            )

            StatBubble(
                emoji: "⭐",
                value: "\(viewModel.completedChapterCount)",
                label: L.s(.chaptersCompleted),
                color: GeniColor.yellow
            )

            Button {
                HapticManager.selection()
                viewModel.showRewards = true
            } label: {
                VStack(spacing: 6) {
                    Text("🪙")
                        .font(.system(size: 22))

                    Text("\(rewards.coins)")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text(L.s(.coins))
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .brutalistCard(color: GeniColor.card, borderWidth: 3)
                .overlay(Color.clear.zoomSource(id: "rewards", in: rewardsNamespace))
            }
        }
    }

    private var missionCard: some View {
        Group {
            if viewModel.todayFullChapterCompleted {
                missionCompleteCard
            } else {
                missionActiveCard
            }
        }
    }

    private var missionCompleteCard: some View {
        let requiresReading = viewModel.persistence.activeProfile?.readingMode == .required

        return VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 48))

            Text(L.s(.noChapterToday))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.border)

            Text(L.s(.comeBackTomorrow))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.black)

            HStack(spacing: 12) {
                MissionCheckItem(label: L.s(.mathDone), done: true)
                if requiresReading {
                    MissionCheckItem(label: L.s(.readingDone2), done: viewModel.todayReadingCompleted)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .brutalistCard(color: GeniColor.card)
    }

    private var missionActiveCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.s(.todaysMission))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(viewModel.persistence.activeProfile?.readingMode == .hidden
                         ? "🧮 \(L.s(.mathOnly))"
                         : "📚 \(L.s(.mathAndReading))")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                MissionProgressItem(
                    emoji: "🧮",
                    label: L.s(.mathProgress),
                    progress: "\(viewModel.todayChapterExercisesCompleted)/20",
                    done: viewModel.todayMathCompleted,
                    color: GeniColor.blue
                )

                if viewModel.persistence.activeProfile?.readingMode != .hidden {
                    Rectangle()
                        .fill(GeniColor.border.opacity(0.15))
                        .frame(width: 2, height: 50)

                    MissionProgressItem(
                        emoji: "📖",
                        label: viewModel.persistence.activeProfile?.readingMode == .optional
                            ? "\(L.s(.readingProgress)) \(L.s(.optionalLabel))"
                            : L.s(.readingProgress),
                        progress: readingProgressText,
                        done: viewModel.todayReadingCompleted,
                        color: GeniColor.green
                    )
                }
            }

            Button {
                HapticManager.impact(.medium)
                if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted
                    && viewModel.persistence.activeProfile?.readingMode == .required {
                    viewModel.startReading()
                } else if !viewModel.todayMathCompleted {
                    viewModel.startChapter()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(missionButtonText)
                    if !viewModel.todayMathCompleted && !viewModel.todayChapterInProgress {
                        Text("▶️")
                            .font(.system(size: 14))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrutalistButton(color: missionButtonColor))

            // Optional reading button for age 6 after math is done
            if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted
                && viewModel.persistence.activeProfile?.readingMode == .optional {
                Button {
                    HapticManager.impact(.medium)
                    viewModel.startReading()
                } label: {
                    HStack(spacing: 8) {
                        Text("📖")
                            .font(.system(size: 14))
                        Text(L.s(.startReading))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrutalistButton(color: GeniColor.green))
            }

        }
        .padding(20)
        .brutalistCard(color: GeniColor.card)
    }

    private var readingProgressText: String {
        if viewModel.todayReadingCompleted {
            return "✓"
        }
        guard let profile = viewModel.persistence.activeProfile else { return "0 \(L.s(.minutes))" }
        let mins = ReadingText.targetReadingSeconds(for: profile.age) / 60
        return "0/\(mins) \(L.s(.minutes))"
    }

    private var missionButtonText: String {
        if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted
            && viewModel.persistence.activeProfile?.readingMode == .required {
            return L.s(.startReading)
        } else if viewModel.todayChapterInProgress {
            return L.s(.continueChapter)
        } else {
            return L.s(.start)
        }
    }

    private var missionButtonColor: Color {
        if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted
            && viewModel.persistence.activeProfile?.readingMode == .required {
            return GeniColor.green
        }
        return GeniColor.blue
    }

    private var specialModesSection: some View {
        VStack(spacing: 12) {
            if viewModel.challengeWindowStarted, let special = viewModel.specialChapterAvailable, !viewModel.challengeTimeExpired {
                specialChapterCard(type: special)
            }

            if viewModel.challengeTimeExpired {
                challengesClosedCard
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L.s(.extraModes))
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.black)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Spacer()

                        if viewModel.challengeWindowStarted {
                            ChallengeCountdown(viewModel: viewModel)
                        }
                    }

                    if !viewModel.challengeWindowStarted {
                        Text(challengeUnlockHint)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    quickChallengeCards(isEnabled: viewModel.canStartChallengeModes)
                }
            }
        }
    }

    private var challengesClosedCard: some View {
        VStack(spacing: 12) {
            Text("😴")
                .font(.system(size: 48))

            Text(L.s(.challengesClosed))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.border)

            Text(L.s(.seeYouTomorrow))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.black)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .brutalistCard(color: GeniColor.card)
    }

    private func specialChapterCard(type: ChapterType) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(specialChapterEmoji(type))
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(L.s(.specialChallenge))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(specialChapterColor(type))
                        .textCase(.uppercase)

                    Text(specialChapterTitle(type))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }

                Spacer()

                Text("✨")
                    .font(.system(size: 28))
            }

            Button {
                HapticManager.specialChapter()
                viewModel.startChapter(type: type)
            } label: {
                Text(L.s(.startChapter))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrutalistButton(color: specialChapterColor(type)))
        }
        .padding(20)
        .brutalistCard(color: GeniColor.card)
    }

    private func quickChallengeCards(isEnabled: Bool) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                QuickChallengeCard(
                    title: L.s(.timeAttack),
                    emoji: "⏱️",
                    color: GeniColor.orange,
                    isEnabled: isEnabled
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .timeAttack)
                }

                QuickChallengeCard(
                    title: L.s(.perfectRun),
                    emoji: "👑",
                    color: GeniColor.purple,
                    isEnabled: isEnabled
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .perfectRun)
                }

                if let profile = viewModel.persistence.activeProfile {
                    ForEach(profile.operationsEnabled, id: \.rawValue) { op in
                        QuickChallengeCard(
                            title: "\(op.symbol) \(L.s(.spotlightChapter))",
                            emoji: "🔍",
                            color: GeniColor.cyan,
                            isEnabled: isEnabled
                        ) {
                            HapticManager.specialChapter()
                            viewModel.startChapter(type: .operationSpotlight, spotlightOp: op)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private func specialChapterIcon(_ type: ChapterType) -> String {
        switch type {
        case .boss: return "shield.fill"
        case .streak: return "flame.fill"
        case .timeAttack: return "timer"
        case .perfectRun: return "crown.fill"
        case .operationSpotlight: return "scope"
        default: return "star.fill"
        }
    }

    private func specialChapterEmoji(_ type: ChapterType) -> String {
        switch type {
        case .boss: return "🛡️"
        case .streak: return "🔥"
        case .timeAttack: return "⏱️"
        case .perfectRun: return "👑"
        case .operationSpotlight: return "🔍"
        default: return "⭐"
        }
    }

    private func specialChapterColor(_ type: ChapterType) -> Color {
        switch type {
        case .boss: return GeniColor.pink
        case .streak: return GeniColor.orange
        case .timeAttack: return GeniColor.orange
        case .perfectRun: return GeniColor.purple
        case .operationSpotlight: return GeniColor.cyan
        default: return GeniColor.blue
        }
    }

    private func specialChapterTitle(_ type: ChapterType) -> String {
        switch type {
        case .boss: return L.s(.bossChapter)
        case .streak: return L.s(.streakBonus)
        case .timeAttack: return L.s(.timeAttack)
        case .perfectRun: return L.s(.perfectRun)
        case .operationSpotlight: return L.s(.spotlightChapter)
        default: return L.s(.specialChallenge)
        }
    }

    private var challengeUnlockHint: String {
        switch viewModel.persistence.activeProfile?.readingMode {
        case .required:
            return L.s(.finishMissionToUnlockChallenges)
        default:
            return L.s(.finishMathToUnlockChallenges)
        }
    }
}

struct MissionProgressItem: View {
    let emoji: String
    let label: String
    let progress: String
    let done: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                if done {
                    Text("✅")
                        .font(.system(size: 18))
                        .frame(width: 32, height: 32)
                } else {
                    Text(emoji)
                        .font(.system(size: 18))
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.12))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)

                Text(done ? "✓" : progress)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(done ? GeniColor.green : GeniColor.border)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct MissionCheckItem: View {
    let label: String
    let done: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(done ? "✅" : "⬜")
                .font(.system(size: 16))

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(done ? GeniColor.green : .black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(done ? GeniColor.green.opacity(0.1) : Color.clear)
        .overlay(Rectangle().stroke(done ? GeniColor.green : GeniColor.border.opacity(0.2), lineWidth: 2))
    }
}

struct StatBubble: View {
    let emoji: String
    let value: String
    let label: String
    var sublabel: String? = nil
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 22))

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            VStack(spacing: 1) {
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let sublabel {
                    Text(sublabel)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .brutalistCard(color: GeniColor.card, borderWidth: 3)
    }
}

struct QuickChallengeCard: View {
    let title: String
    let emoji: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))

                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .brutalistCard(color: GeniColor.card, borderWidth: 3)
            .opacity(isEnabled ? 1.0 : 0.45)
        }
        .disabled(!isEnabled)
    }
}

struct ChallengeCountdown: View {
    let viewModel: AppViewModel
    @State private var secondsLeft: Int = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            Text("⏳")
                .font(.system(size: 14))
            Text(timeString)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(secondsLeft <= 60 ? GeniColor.pink : GeniColor.green)
                .monospacedDigit()
        }
        .onAppear {
            secondsLeft = viewModel.challengeSecondsRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let remaining = viewModel.challengeSecondsRemaining()
                if remaining != secondsLeft {
                    secondsLeft = remaining
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var timeString: String {
        let mins = secondsLeft / 60
        let secs = secondsLeft % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private extension View {
    @ViewBuilder
    func zoomSource<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
