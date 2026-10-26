import SwiftUI

/// At most seven games (special, two modes, four operations), in one or two compact rows.
struct ChallengesCard: View {
    let viewModel: AppViewModel
    let summary: TodaySummary
    @Environment(\.geniExpandedLayout) private var expanded
    var compact = false

    private var columnCount: Int {
        expanded && items.count <= 5 ? items.count : (items.count <= 3 ? items.count : (items.count + 1) / 2)
    }

    private var items: [ChallengeItem] {
        var items: [ChallengeItem] = []
        // Keep eligible special games visible even when the window closes.
        if let special = summary.specialChapter ?? viewModel.specialChapterAvailable {
            items.append(ChallengeItem(
                emoji: special == .boss ? "🛡️" : "🔥",
                title: L.s(special == .boss ? .bossChapter : .streakBonus),
                identifier: "home.challenge.\(special.rawValue)",
                isSpecial: true
            ) { viewModel.startChapter(type: special) })
        } else {
            // Same slots every day: the special game shows locked until one is earned.
            items.append(ChallengeItem(
                emoji: "🔥",
                title: L.s(.streakBonus),
                identifier: "home.challenge.special",
                isAvailable: false
            ) {})
        }
        items.append(ChallengeItem(emoji: "⏱️", title: L.s(.timeAttack),
                                   identifier: "home.challenge.timeAttack") {
            viewModel.startChapter(type: .timeAttack)
        })
        items.append(ChallengeItem(emoji: "👑", title: L.s(.perfectRun),
                                   identifier: "home.challenge.perfectRun") {
            viewModel.startChapter(type: .perfectRun)
        })
        for operation in viewModel.persistence.activeProfile?.operationsEnabled ?? [] {
            items.append(ChallengeItem(emoji: operation.emoji, title: operation.displayName,
                                       identifier: "home.challenge.operationSpotlight.\(operation.rawValue)") {
                viewModel.startChapter(type: .operationSpotlight, spotlightOp: operation)
            })
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎮 \(L.s(.challengesTitle))")
                    .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 8)
                if summary.showsExtras {
                    ChallengeCountdown(viewModel: viewModel)
                } else {
                    Text("🔒")
                        .accessibilityHidden(true)
                }
            }
            .frame(height: expanded ? 36 : 28)

            let games = items
            VStack(spacing: 8) {
                ForEach(0..<((games.count + columnCount - 1) / columnCount), id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(Array(games.dropFirst(row * columnCount).prefix(columnCount))) { item in
                            challengeButton(item)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(expanded ? 24 : 12)
        .frame(maxWidth: .infinity)
        .brutalistCard(color: GeniColor.card, borderWidth: 3)
    }

    private func challengeButton(_ item: ChallengeItem) -> some View {
        Button(action: item.action) {
            let enabled = summary.showsExtras && item.isAvailable
            VStack(spacing: 4) {
                Text(item.emoji)
                    .font(.system(size: expanded ? 72 : (compact ? 32 : 36)))
                    .frame(width: expanded ? 88 : (compact ? 48 : 52), height: expanded ? 88 : (compact ? 48 : 52))
                    .grayscale(enabled ? 0 : 1)
                    .opacity(enabled ? 1 : 0.35)
                    .overlay(alignment: .topTrailing) {
                        if item.isSpecial && enabled {
                            Text("✨").font(.system(size: 16)).offset(x: 4, y: -4)
                        }
                    }
                Text(item.title)
                    .font(.system(size: expanded ? 17 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(enabled ? Color.black : Color.black.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(height: expanded ? 24 : 16)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(KidPressStyle())
        .disabled(!(summary.showsExtras && item.isAvailable))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityIdentifier(item.identifier)
    }
}

private struct ChallengeItem: Identifiable {
    let emoji: String
    let title: String
    let identifier: String
    var isSpecial = false
    var isAvailable = true
    let action: () -> Void

    var id: String { identifier }
}

struct ChallengeCountdown: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let viewModel: AppViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let seconds = viewModel.challengeSecondsRemaining()
            let time = String(format: "%d:%02d", seconds / 60, seconds % 60)
            HStack(spacing: 4) {
                Text("⏳").accessibilityHidden(true)
                Text(time).monospacedDigit()
            }
            .font(.system(expanded ? .title3 : .subheadline, design: .rounded, weight: .black))
            .foregroundStyle((seconds <= 60 ? GeniColor.pink : GeniColor.green).deep())
            .padding(.horizontal, 10)
            .frame(height: 28)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L.s(.challengeTimeLeft))
            .accessibilityValue(time)
        }
    }
}
