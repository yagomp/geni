import SwiftUI

struct RewardsView: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var detailBadge: Badge?

    private var rewards: RewardState { viewModel.rewardState }
    private var profile: ChildProfile? { viewModel.persistence.activeProfile }
    private var readingMode: ReadingRequirement? { profile?.readingMode }

    var body: some View {
        Group {
            if iPadScale.isIPad {
                GeometryReader { available in
                    layout(expanded: available.size.width >= 700)
                }
            } else {
                layout(expanded: false)
            }
        }
        .buttonStyle(KidPressStyle())
        .sheet(item: $detailBadge) { badge in
            BadgeDetailSheet(badge: badge, rewards: rewards)
        }
    }

    private func layout(expanded: Bool) -> some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header(expanded: expanded)
                    heroCard(expanded: expanded)
                    if let next = Badge.nextGoal(rewards: rewards, readingMode: readingMode) {
                        NextGoalRow(badge: next, progress: next.progress(in: rewards)) {
                            HapticManager.selection()
                            detailBadge = next
                        }
                    }
                    badgeGrid(expanded: expanded)
                }
                .padding(iPadScale.padding)
                .frame(maxWidth: expanded ? 900 : 720)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.black)
            }
        }
    }

    private func header(expanded: Bool) -> some View {
        HStack {
            KidBackButton {
                HapticManager.selection()
                dismiss()
            }
            .accessibilityIdentifier("rewards.back")

            Spacer()

            Text(L.s(.rewards))
                .font(.system(expanded ? .largeTitle : .title2, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
                .accessibilityIdentifier("rewards.title")

            Spacer()

            Color.clear.frame(width: 56, height: 56)
        }
    }

    private func heroCard(expanded: Bool) -> some View {
        VStack(spacing: expanded ? 24 : 16) {
            HStack(spacing: 24) {
                avatar(expanded: expanded)
                LevelMedallion(level: rewards.level, size: expanded ? 124 : 88)
            }

            SegmentedMeter(fraction: rewards.xpFraction)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(L.s(.level)) \(rewards.level)")
                .accessibilityValue("\(rewards.xp) / \(rewards.xpForNextLevel) \(L.s(.xp))")

            HStack(spacing: expanded ? 32 : 16) {
                stat(value: rewards.coins, label: L.s(.coins)) { CoinIcon(size: expanded ? 44 : 34) }
                stat(value: rewards.streakCount, label: L.s(.streak)) {
                    Text("🔥").font(.system(size: expanded ? 44 : 34))
                }
                if rewards.isStreakFreezeAvailable() {
                    stat(value: 1, label: L.t(
                        "Streak freeze: one missed day this week won't break your streak",
                        no: "Rekkefrys: én dag uten øving denne uken bryter ikke rekken din",
                        es: "Protección de racha: faltar un día esta semana no romperá tu racha",
                        pt: "Proteção de sequência: faltar um dia nesta semana não quebra a tua sequência"
                    )) {
                        Text("🧊").font(.system(size: expanded ? 44 : 34))
                    }
                }
            }
        }
        .padding(expanded ? 24 : 16)
        .frame(maxWidth: .infinity)
        .softSurface(GeniColor.card)
        .compositingGroup()
    }

    private func avatar(expanded: Bool) -> some View {
        let avatar = AvatarOption.find(profile?.avatarId ?? "lion")
        return Text(avatar.emoji)
            // Straight on the card like the home pictures: no tile behind the avatar
            .font(.system(size: expanded ? 104 : 72))
            .shadow(color: GeniColor.border.opacity(0.15), radius: 6, x: 0, y: 4)
            .frame(width: expanded ? 124 : 88, height: expanded ? 124 : 88)
            .accessibilityHidden(true)
    }

    private func stat<Icon: View>(value: Int, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 8) {
            icon()
            Text("\(value)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: value)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
    }

    private func badgeGrid(expanded: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: expanded ? 132 : 96, maximum: expanded ? 180 : 140), spacing: 12)], spacing: 16) {
            ForEach(Badge.sorted(rewards: rewards, readingMode: readingMode)) { badge in
                BadgeTile(badge: badge, rewards: rewards, expanded: expanded) {
                    detailBadge = badge
                }
            }
        }
    }
}

private struct BadgeTile: View {
    let badge: Badge
    let rewards: RewardState
    var expanded = false
    let onTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounced = false

    var body: some View {
        let earned = badge.isEarned(in: rewards)
        Button {
            HapticManager.selection()
            if !reduceMotion {
                bounced = true
                Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    bounced = false
                }
            }
            onTap()
        } label: {
            VStack(spacing: 8) {
                BadgeMedallion(badge: badge, size: expanded ? 112 : 84, earned: earned, progress: badge.progress(in: rewards))
                    .scaleEffect(bounced ? 1.12 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bounced)

                Text(L.s(badge.titleKey))
                    .font(.system(expanded ? .headline : .subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(KidPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.s(badge.titleKey))
        .accessibilityValue(L.s(badge.descriptionKey))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("rewards.badge.\(badge.id)")
    }
}
