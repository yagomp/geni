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
                VStack(spacing: 12) {
                    headerSection(profile: profile, avatar: avatar)
                        .frame(height: hasMultipleProfiles ? 72 : 64)

                    RewardsStrip(rewards: viewModel.rewardState) {
                        viewModel.showRewards = true
                    }
                    .zoomSource(id: "rewards", in: rewardsNamespace)

                    // Date-based challenge availability must also update while home stays open.
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let summary = viewModel.todaySummary
                        GeometryReader { remaining in
                            // State never changes these heights. Reserve 206pt for two
                            // challenge rows; Today needs 236pt on the smallest iPhone.
                            let cardSpace = remaining.size.height - 12
                            let todayHeight = min(cardSpace - 206, max(236, cardSpace * 0.56))
                            let compact = todayHeight < 264
                            VStack(spacing: 12) {
                                TodayCard(summary: summary, compact: compact) { action in
                                    if action.isReading {
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
                .frame(maxWidth: 720)
                .padding(.horizontal, iPadScale.padding)
                // Includes the cards' 4pt offset shadows, including on a home-button iPhone.
                .padding(.vertical, 12)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
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

    private func headerSection(profile: ChildProfile?, avatar: AvatarOption) -> some View {
        HStack(spacing: 8) {
            Button {
                HapticManager.selection()
                if hasMultipleProfiles {
                    viewModel.switchProfile()
                } else {
                    showAvatarPicker = true
                }
            } label: {
                Text(avatar.emoji)
                    .font(.system(size: 38))
                    .frame(width: 64, height: 64)
                    .brutalistCard(color: GeniColor.card, borderWidth: 3)
            }
            .buttonStyle(KidPressStyle())
            .accessibilityLabel(L.s(hasMultipleProfiles ? .selectProfile : .chooseAvatar))
            .accessibilityIdentifier("home.avatar")

            Text(profile?.nickname ?? "")
                .font(.system(.title2, design: .rounded, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
                .accessibilityIdentifier("home.name")

            Spacer(minLength: 0)

            if hasMultipleProfiles {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.persistence.profiles.filter { $0.id != viewModel.persistence.activeProfileId }) { sibling in
                            Button {
                                HapticManager.impact(.medium)
                                viewModel.selectProfile(sibling)
                            } label: {
                                Text(AvatarOption.find(sibling.avatarId).emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 64, height: 64)
                                    .brutalistCard(color: GeniColor.card, borderWidth: 3)
                            }
                            .buttonStyle(KidPressStyle())
                            .accessibilityLabel(sibling.nickname)
                            .accessibilityIdentifier("home.sibling.\(sibling.nickname)")
                        }
                    }
                    .padding(4)
                }
                .scrollIndicators(.hidden)
                .frame(minWidth: 72, idealWidth: 72, maxWidth: 144)
                .frame(height: 72)
            }

            Button {
                HapticManager.selection()
                viewModel.showParentSettings = true
            } label: {
                Text("⚙️")
                    .font(.system(size: 30))
                    .frame(width: 44, height: 56)
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
