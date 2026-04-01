import SwiftUI

struct ChildHomeView: View {
    let viewModel: AppViewModel
    @State private var showAvatarPicker = false
    @State private var showProfileSwitcher = false
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
                    Spacer()
                    progressMapSection
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
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherSheet(
                profiles: viewModel.persistence.profiles,
                activeProfileId: viewModel.persistence.activeProfileId,
                onSelect: { profile in
                    showProfileSwitcher = false
                    if profile.id != viewModel.persistence.activeProfileId {
                        viewModel.selectProfile(profile)
                    }
                },
                onAddProfile: {
                    showProfileSwitcher = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showProfileCreation = true
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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
        HStack(spacing: 16) {
            Button {
                HapticManager.selection()
                if hasMultipleProfiles {
                    showProfileSwitcher = true
                } else {
                    showAvatarPicker = true
                }
            } label: {
                HStack(spacing: 12) {
                    Text(avatar.emoji)
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 3)
                        )
                        .background(
                            Rectangle()
                                .fill(GeniColor.border)
                                .offset(x: 3, y: 3)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile?.nickname ?? "")
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundStyle(GeniColor.border)

                        HStack(spacing: 4) {
                            Text("\(L.s(.level)) \(rewards.level)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }

                    if hasMultipleProfiles {
                        HStack(spacing: 4) {
                            Text("🔄")
                                .font(.system(size: 12))
                            Text(L.s(.changeProfile))
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(GeniColor.border)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                    }
                }
            }

            Spacer()

            Button {
                HapticManager.selection()
                viewModel.showParentSettings = true
            } label: {
                Text("⚙️")
                    .font(.system(size: 24))
            }
        }
    }

    private func statsRow(rewards: RewardState) -> some View {
        HStack(spacing: 8) {
            StatBubble(
                emoji: "🔥",
                value: "\(rewards.streakCount)",
                label: rewards.streakCount == 1 ? L.s(.day) : L.s(.days),
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
        VStack(spacing: 16) {
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
                if viewModel.persistence.activeProfile?.readingMode != .hidden {
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

                    if viewModel.persistence.activeProfile?.ageGroup == .middle || viewModel.persistence.activeProfile?.ageGroup == .older {
                        HStack(spacing: 6) {
                            Text(viewModel.currentMathTopic.emoji)
                                .font(.system(size: 14))
                            Text(viewModel.currentMathTopic.displayName)
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(GeniColor.blue)
                        }
                    }
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
            if let special = viewModel.specialChapterAvailable, !viewModel.challengeTimeExpired {
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

                        if viewModel.todayFullChapterCompleted {
                            ChallengeCountdown(viewModel: viewModel)
                        }
                    }

                    quickChallengeCards
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

    private var quickChallengeCards: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                QuickChallengeCard(
                    title: L.s(.timeAttack),
                    emoji: "⏱️",
                    color: GeniColor.orange
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .timeAttack)
                }

                QuickChallengeCard(
                    title: L.s(.perfectRun),
                    emoji: "👑",
                    color: GeniColor.purple
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .perfectRun)
                }

                if let profile = viewModel.persistence.activeProfile {
                    ForEach(profile.operationsEnabled, id: \.rawValue) { op in
                        QuickChallengeCard(
                            title: "\(op.symbol) \(L.s(.spotlightChapter))",
                            emoji: "🔍",
                            color: GeniColor.cyan
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

    private var progressMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.persistence.activeProfile?.ageGroup == .middle || viewModel.persistence.activeProfile?.ageGroup == .older {
                Text(L.s(.topicProgress))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)

                TopicMapView(topicProgress: viewModel.topicProgress)
            } else {
                Text(L.s(.progressMap))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)

                ProgressMapView(
                    completedCount: viewModel.completedChapterCount,
                    rewards: viewModel.rewardState
                )
            }
        }
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
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 22))

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
    let action: () -> Void

    var body: some View {
        Button {
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
        }
    }
}

struct TopicMapView: View {
    let topicProgress: TopicProgress

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MathTopic.allCases, id: \.rawValue) { topic in
                    let isUnlocked = topicProgress.isUnlocked(topic)
                    let isCurrent = topicProgress.currentTopic() == topic
                    let stars = topicProgress.stars(for: topic)

                    VStack(spacing: 6) {
                        Text(topic.emoji)
                            .font(.system(size: 22))
                            .opacity(isUnlocked ? 1.0 : 0.4)

                        Text("\(topic.order + 1)")
                            .font(.system(.caption2, design: .rounded, weight: .black))
                            .foregroundStyle(isCurrent ? .white : (isUnlocked ? GeniColor.border : .gray))

                        if isUnlocked && stars > 0 {
                            Text("⭐\(stars)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(GeniColor.border)
                        } else if !isUnlocked {
                            Text("🔒")
                                .font(.system(size: 10))
                        }
                    }
                    .frame(width: 56, height: 72)
                    .background(isCurrent ? GeniColor.blue : (isUnlocked ? GeniColor.card : Color.gray.opacity(0.1)))
                    .overlay(Rectangle().stroke(isCurrent ? GeniColor.blue : (isUnlocked ? GeniColor.border : Color.gray.opacity(0.3)), lineWidth: isCurrent ? 3 : 2))
                    .background(Rectangle().fill(GeniColor.border.opacity(isUnlocked ? 1 : 0.2)).offset(x: 2, y: 2))
                }
            }
            .padding(.vertical, 4)
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
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

struct ProfileSwitcherSheet: View {
    let profiles: [ChildProfile]
    let activeProfileId: String?
    let onSelect: (ChildProfile) -> Void
    let onAddProfile: () -> Void

    var body: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text(L.s(.whosPlaying))
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(profiles) { profile in
                        let avatar = AvatarOption.find(profile.avatarId)
                        let isActive = profile.id == activeProfileId

                        Button {
                            HapticManager.impact(.medium)
                            onSelect(profile)
                        } label: {
                            VStack(spacing: 8) {
                                Text(avatar.emoji)
                                    .font(.system(size: 36))

                                Text(profile.nickname)
                                    .font(.system(.subheadline, design: .rounded, weight: .black))
                                    .foregroundStyle(GeniColor.border)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                if isActive {
                                    Text("✅")
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity)
                            .background(GeniColor.card)
                            .overlay(
                                Rectangle()
                                    .stroke(isActive ? GeniColor.green : GeniColor.border, lineWidth: isActive ? 4 : 3)
                            )
                            .background(
                                Rectangle()
                                    .fill(isActive ? GeniColor.green : GeniColor.border)
                                    .offset(x: 3, y: 3)
                            )
                        }
                    }

                    Button {
                        HapticManager.impact(.medium)
                        onAddProfile()
                    } label: {
                        VStack(spacing: 8) {
                            Text("➕")
                                .font(.system(size: 36))

                            Text(L.s(.add))
                                .font(.system(.subheadline, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .background(GeniColor.card)
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 3)
                        )
                        .background(
                            Rectangle()
                                .fill(GeniColor.border)
                                .offset(x: 3, y: 3)
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}
