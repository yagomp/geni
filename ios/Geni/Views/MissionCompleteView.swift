import SwiftUI

struct MissionCompleteView: View {
    let mathStars: Int
    let mathCoins: Int
    let mathXP: Int
    let readingCoins: Int
    let bonusCoins: Int
    let rewards: RewardState
    let onContinue: () -> Void

    var body: some View {
        GeniLearningLayout {
            MissionCompleteViewLayout(mathStars: mathStars, mathCoins: mathCoins, mathXP: mathXP, readingCoins: readingCoins, bonusCoins: bonusCoins, rewards: rewards, onContinue: onContinue)
        }
    }
}

private struct MissionCompleteViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let mathStars: Int
    let mathCoins: Int
    let mathXP: Int
    let readingCoins: Int
    let bonusCoins: Int
    let rewards: RewardState
    let onContinue: () -> Void

    private var totalCoins: Int {
        mathCoins + readingCoins + bonusCoins
    }

    var body: some View {
        CompletionScaffold(mascot: .cheer, title: L.s(.missionComplete)) {
            CompletionStars(stars: mathStars)

            VStack(spacing: expanded ? 24 : 10) {
                CoinLine(icon: "➕", tint: GeniColor.blue, label: L.s(.mathDone), coins: mathCoins)
                divider
                CoinLine(icon: "📖", tint: GeniColor.green, label: L.s(.readingDone2), coins: readingCoins)

                if bonusCoins > 0 {
                    divider
                    CoinLine(icon: "✨", tint: GeniColor.yellow, label: L.s(.bonusEarned), coins: bonusCoins)
                }

                Rectangle()
                    .fill(GeniColor.hairline)
                    .frame(height: 3)

                HStack {
                    Text(L.s(.total))
                    Spacer()
                    Text("+\(totalCoins) 🪙")
                }
                .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
            }
            .completionCard()

            HStack(spacing: expanded ? 16 : 12) {
                StatTile(icon: "🔥", value: "\(rewards.streakCount)", label: rewards.streakCount == 1 ? L.s(.day) : L.s(.days))
                StatTile(icon: "⭐", value: "\(mathStars)/5", label: L.s(.stars))
                StatTile(icon: "🪙", value: "\(rewards.coins)", label: L.s(.coins))
            }
        } actions: {
            CompletionButton(title: L.s(.done), color: GeniColor.blue, identifier: "missionComplete.done", action: onContinue)
        }
        .task {
            do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
            HapticManager.coinRipple(count: totalCoins)
        }
        .onAppear { HapticManager.correctAnswer() }
    }

    private var divider: some View {
        Rectangle()
            .fill(GeniColor.border.opacity(0.1))
            .frame(height: 2)
    }
}

/// One mission part and the coins it earned.
private struct CoinLine: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let icon: String
    let tint: Color
    let label: String
    let coins: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .softSurface(tint, radiusScale: 0.5)

            Text(label)
                .font(.system(expanded ? .title2 : .body, design: .rounded, weight: .semibold))
                .foregroundStyle(GeniColor.border)

            Spacer()

            Text("+\(coins) 🪙")
                .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
        }
    }
}

/// A small card with an icon, a number and its unit.
private struct StatTile: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
            Text(label)
                .font(.system(expanded ? .subheadline : .caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, expanded ? 16 : 10)
        .softSurface(GeniColor.card)
    }
}
