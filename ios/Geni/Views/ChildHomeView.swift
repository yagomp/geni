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

        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            GeometryReader { geo in
                let expanded = iPadScale.isIPad && geo.size.width >= 700 && geo.size.height >= 800
                let spacing: CGFloat = expanded ? 20 : 12
                VStack(spacing: spacing) {
                    headerSection(profile: profile, avatar: avatar, expanded: expanded)
                        .frame(height: expanded ? 88 : (hasMultipleProfiles ? 72 : 64))

                    // Date-based challenge availability must also update while home stays open.
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let summary = viewModel.todaySummary
                        GeometryReader { remaining in
                            // Share the space reclaimed from the rewards strip. Keep room
                            // for both challenge rows and Today's labels on a small phone.
                            let cardSpace = max(0, remaining.size.height - spacing)
                            let spotlightCount = profile?.showsOperationSpotlights == true ? profile?.operationsEnabled.count ?? 0 : 0
                            let challengeRows = (3 + spotlightCount) > 5 ? 2 : 1
                            let minimumChallengeHeight: CGFloat = expanded ? (challengeRows == 1 ? 232 : 368) : 218
                            let minimumTodayHeight: CGFloat = expanded ? 380 : 236
                            let todayShare: CGFloat = expanded && challengeRows == 1 ? 0.66 : 0.56
                            let todayHeight = max(0, min(cardSpace - minimumChallengeHeight, max(minimumTodayHeight, cardSpace * todayShare)))
                            let compact = todayHeight < (expanded ? 420 : 264)
                            VStack(spacing: spacing) {
                                TodayCard(summary: summary, compact: compact) { action in
                                    if action == .reading {
                                        viewModel.startReading()
                                    } else {
                                        viewModel.startChapter()
                                    }
                                }
                                .frame(height: todayHeight)

                                ChallengesCard(viewModel: viewModel, summary: summary, compact: compact)
                                    .frame(height: cardSpace - todayHeight)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: expanded ? 820 : 720)
                .environment(\.geniExpandedLayout, expanded)
                .padding(.horizontal, iPadScale.padding)
                // Includes the cards' soft shadows, including on a home-button iPhone.
                .padding(.vertical, expanded ? 24 : 12)
                .frame(maxHeight: expanded ? 1120 : .infinity)
                .frame(width: geo.size.width, height: geo.size.height, alignment: expanded ? .center : .top)
            }
            .foregroundStyle(GeniColor.border)
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showProfileCreation) {
            ProfileCreationView(onComplete: { profile in
                viewModel.persistence.saveProfile(profile)
                viewModel.selectProfile(profile)
                showProfileCreation = false
            }, existingNames: viewModel.persistence.profiles.map(\.nickname), onBack: {
                showProfileCreation = false
            })
        }
    }

    private func headerSection(profile: ChildProfile?, avatar: AvatarOption, expanded: Bool) -> some View {
        HStack(spacing: expanded ? 8 : 6) {
            Button {
                HapticManager.selection()
                if hasMultipleProfiles {
                    viewModel.switchProfile()
                } else {
                    showAvatarPicker = true
                }
            } label: {
                Text(avatar.emoji)
                    .font(.system(size: expanded ? 52 : 38))
                    .frame(width: expanded ? 88 : 56, height: expanded ? 88 : 56)
                    .softSurface(GeniColor.card, radiusScale: 1.5)
            }
            .buttonStyle(KidPressStyle())
            .accessibilityLabel(L.s(hasMultipleProfiles ? .selectProfile : .chooseAvatar))
            .accessibilityIdentifier("home.avatar")

            Text(profile?.nickname ?? "")
                .font(.system(expanded ? .largeTitle : .title2, design: .rounded, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The name yields before the coin pill or profile controls do.
                .layoutPriority(-1)
                .accessibilityIdentifier("home.name")

            if hasMultipleProfiles {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.persistence.profiles.filter { $0.id != viewModel.persistence.activeProfileId }) { sibling in
                            Button {
                                HapticManager.impact(.medium)
                                viewModel.selectProfile(sibling)
                            } label: {
                                Text(AvatarOption.find(sibling.avatarId).emoji)
                                    .font(.system(size: expanded ? 44 : 30))
                                    .frame(width: expanded ? 88 : 48, height: expanded ? 88 : 48)
                                    .softSurface(GeniColor.card, radiusScale: 1.5)
                            }
                            .buttonStyle(KidPressStyle())
                            .accessibilityLabel(sibling.nickname)
                            .accessibilityIdentifier("home.sibling.\(sibling.nickname)")
                        }
                    }
                    .padding(4)
                }
                .scrollIndicators(.hidden)
                .frame(width: expanded ? 192 : 56)
                .frame(height: expanded ? 96 : 72)
            }

            Button {
                HapticManager.selection()
                viewModel.showRewards = true
            } label: {
                HStack(spacing: 4) {
                    CoinIcon(size: expanded ? 36 : 24)
                        .accessibilityHidden(true)
                    Text("\(viewModel.rewardState.coins)")
                        .font(.system(size: expanded ? 30 : 22, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("home.coins")
                }
                .padding(.horizontal, expanded ? 16 : 10)
                .frame(height: expanded ? 72 : 48)
                .softSurface(GeniColor.card)
                .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(KidPressStyle())
            .accessibilityLabel(L.s(.rewards))
            .accessibilityValue("\(L.s(.coins)), \(viewModel.rewardState.coins)")
            .accessibilityIdentifier("home.rewards")
            .zoomSource(id: "rewards", in: rewardsNamespace)

            Button {
                HapticManager.selection()
                viewModel.showParentSettings = true
            } label: {
                Text("⚙️")
                    .font(.system(size: expanded ? 40 : 30))
                    .frame(width: expanded ? 64 : 44, height: expanded ? 72 : 56)
                    .zoomSource(id: "settings", in: settingsNamespace)
            }
            .buttonStyle(KidPressStyle())
            .accessibilityLabel(L.s(.settings))
            .accessibilityIdentifier("home.settings")
        }
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
