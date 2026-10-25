import SwiftUI

struct RewardsView: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var detailBadge: Badge?
    @State private var showAvatarChooser = false

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
        .sheet(isPresented: $showAvatarChooser) {
            AvatarChooserSheet(viewModel: viewModel)
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
                avatarButton(expanded: expanded)
                LevelMedallion(level: rewards.level, size: expanded ? 124 : 88)
            }

            SegmentedMeter(fraction: rewards.xpFraction)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(L.s(.level)) \(rewards.level)")
                .accessibilityValue("\(rewards.xp) / \(rewards.xpForNextLevel) \(L.s(.xp))")

            HStack(spacing: 32) {
                stat(value: rewards.coins, label: L.s(.coins)) { CoinIcon(size: expanded ? 44 : 34) }
                stat(value: rewards.streakCount, label: L.s(.streak)) {
                    Text("🔥").font(.system(size: expanded ? 44 : 34))
                }
            }
        }
        .padding(expanded ? 24 : 16)
        .frame(maxWidth: .infinity)
        .background(GeniColor.card)
        .clipShape(GeniShape())
        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 4))
        .background(GeniShape().fill(GeniColor.border).offset(x: 6, y: 6))
        .compositingGroup()
    }

    private func avatarButton(expanded: Bool) -> some View {
        let avatar = AvatarOption.find(profile?.avatarId ?? "lion")
        return Button {
            HapticManager.selection()
            showAvatarChooser = true
        } label: {
            Text(avatar.emoji)
                .font(.system(size: expanded ? 76 : 52))
                .frame(width: expanded ? 124 : 88, height: expanded ? 124 : 88)
                .background(avatar.color.soft(0.5))
                .clipShape(GeniShape())
                .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                .background(GeniShape().fill(GeniColor.border).offset(x: 4, y: 4))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: 32, height: 32)
                        .background(GeniColor.card, in: Circle())
                        .overlay(Circle().stroke(GeniColor.border, lineWidth: 2))
                        .offset(x: 8, y: 8)
                }
                .compositingGroup()
        }
        .buttonStyle(KidPressStyle())
        .accessibilityLabel(L.s(.chooseAvatar))
        .accessibilityIdentifier("rewards.avatar")
    }

    private func stat<Icon: View>(value: Int, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 8) {
            icon()
            Text("\(value)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: value)
        }
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
