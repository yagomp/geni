import SwiftUI

struct ChildHomeView: View {
    let viewModel: AppViewModel
    @State private var appeared = false
    @State private var streakBounce = 0
    @State private var showAvatarPicker = false
    @State private var missionPulse = false

    var body: some View {
        let profile = viewModel.persistence.activeProfile
        let avatar = AvatarOption.find(profile?.avatarId ?? "lion")
        let rewards = viewModel.rewardState

        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection(profile: profile, avatar: avatar, rewards: rewards)
                    statsRow(rewards: rewards)
                    missionCard
                    specialModesSection
                    progressMapSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            appeared = true
            streakBounce += 1
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                missionPulse = true
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(viewModel: viewModel)
        }
    }

    private func headerSection(profile: ChildProfile?, avatar: AvatarOption, rewards: RewardState) -> some View {
        HStack(spacing: 16) {
            Button {
                HapticManager.selection()
                showAvatarPicker = true
            } label: {
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
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.nickname ?? "")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)

                HStack(spacing: 4) {
                    Text("\(L.s(.level)) \(rewards.level)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(GeniColor.purple)
                }
            }

            Spacer()

            Button {
                HapticManager.selection()
                viewModel.showParentSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5), value: appeared)
    }

    private func statsRow(rewards: RewardState) -> some View {
        HStack(spacing: 8) {
            StatBubble(
                icon: "flame.fill",
                value: "\(rewards.streakCount)",
                label: rewards.streakCount == 1 ? L.s(.day) : L.s(.days),
                color: GeniColor.orange
            )
            .symbolEffect(.bounce, value: streakBounce)

            StatBubble(
                icon: "star.fill",
                value: "\(viewModel.completedChapterCount)",
                label: L.s(.chaptersCompleted),
                color: GeniColor.yellow
            )

            Button {
                HapticManager.selection()
                viewModel.showRewards = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title3)
                        .foregroundStyle(GeniColor.yellow)

                    Text("\(rewards.coins)")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text(L.s(.coins))
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .brutalistCard(color: GeniColor.card, borderWidth: 3)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var missionCard: some View {
        Group {
            if viewModel.todayFullChapterCompleted {
                missionCompleteCard
            } else {
                missionActiveCard
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
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
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                MissionCheckItem(label: L.s(.mathDone), done: true)
                MissionCheckItem(label: L.s(.readingDone2), done: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .brutalistCard(color: GeniColor.green.opacity(0.1))
    }

    private var missionActiveCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.s(.todaysMission))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(GeniColor.blue)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text("📚 \(L.s(.mathAndReading))")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                MissionProgressItem(
                    icon: "plus",
                    label: L.s(.mathProgress),
                    progress: "\(viewModel.todayChapterExercisesCompleted)/20",
                    done: viewModel.todayMathCompleted,
                    color: GeniColor.blue
                )

                Rectangle()
                    .fill(GeniColor.border.opacity(0.15))
                    .frame(width: 2, height: 50)

                MissionProgressItem(
                    icon: "book.fill",
                    label: L.s(.readingProgress),
                    progress: readingProgressText,
                    done: viewModel.todayReadingCompleted,
                    color: GeniColor.green
                )
            }

            Button {
                HapticManager.impact(.medium)
                if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted {
                    viewModel.startReading()
                } else if !viewModel.todayMathCompleted {
                    viewModel.startChapter()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(missionButtonText)
                    if !viewModel.todayMathCompleted && !viewModel.todayChapterInProgress {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrutalistButton(color: missionButtonColor))
            .scaleEffect(missionPulse && !viewModel.todayMathCompleted && !viewModel.todayChapterInProgress ? 1.02 : 1.0)
        }
        .padding(20)
        .brutalistCard(color: GeniColor.card)
    }

    private var readingProgressText: String {
        if viewModel.todayReadingCompleted {
            return "✓"
        }
        guard let profile = viewModel.persistence.activeProfile else { return "0 min" }
        let mins = ReadingText.targetReadingSeconds(for: profile.age) / 60
        return "0/\(mins) min"
    }

    private var missionButtonText: String {
        if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted {
            return L.s(.startReading)
        } else if viewModel.todayChapterInProgress {
            return L.s(.continueChapter)
        } else {
            return L.s(.start)
        }
    }

    private var missionButtonColor: Color {
        if viewModel.todayMathCompleted && !viewModel.todayReadingCompleted {
            return GeniColor.green
        }
        return GeniColor.blue
    }

    private var specialModesSection: some View {
        VStack(spacing: 12) {
            if let special = viewModel.specialChapterAvailable {
                specialChapterCard(type: special)
            }

            if viewModel.canStartTimeAttack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.s(.extraModes))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    quickChallengeCards
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(.spring(response: 0.5).delay(0.3), value: appeared)
    }

    private func specialChapterCard(type: ChapterType) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: specialChapterIcon(type))
                    .font(.title2)
                    .foregroundStyle(specialChapterColor(type))

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

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(specialChapterColor(type))
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
        .brutalistCard(color: specialChapterColor(type).opacity(0.08))
    }

    private var quickChallengeCards: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                QuickChallengeCard(
                    title: L.s(.timeAttack),
                    icon: "timer",
                    color: GeniColor.orange
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .timeAttack)
                }

                QuickChallengeCard(
                    title: L.s(.perfectRun),
                    icon: "crown.fill",
                    color: GeniColor.purple
                ) {
                    HapticManager.specialChapter()
                    viewModel.startChapter(type: .perfectRun)
                }

                if let profile = viewModel.persistence.activeProfile {
                    ForEach(profile.operationsEnabled, id: \.rawValue) { op in
                        QuickChallengeCard(
                            title: "\(op.symbol) \(L.s(.spotlightChapter))",
                            icon: "scope",
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
            Text(L.s(.progressMap))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.border)

            ProgressMapView(
                completedCount: viewModel.completedChapterCount,
                rewards: viewModel.rewardState
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(.spring(response: 0.5).delay(0.35), value: appeared)
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
    let icon: String
    let label: String
    let progress: String
    let done: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(GeniColor.green)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.12))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

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
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundStyle(done ? GeniColor.green : .secondary)

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(done ? GeniColor.green : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(done ? GeniColor.green.opacity(0.1) : Color.clear)
        .overlay(Rectangle().stroke(done ? GeniColor.green : GeniColor.border.opacity(0.2), lineWidth: 2))
    }
}

struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
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
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

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
