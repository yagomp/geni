import SwiftUI

struct ReadingCompleteView: View {
    let session: ReadingSession
    let rewards: RewardState
    let bonusAwarded: Bool
    let bonusCoins: Int
    let onContinue: () -> Void

    var body: some View {
        GeniLearningLayout {
            ReadingCompleteViewLayout(session: session, rewards: rewards, bonusAwarded: bonusAwarded, bonusCoins: bonusCoins, onContinue: onContinue)
        }
    }
}

private struct ReadingCompleteViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let session: ReadingSession
    let rewards: RewardState
    let bonusAwarded: Bool
    let bonusCoins: Int
    let onContinue: () -> Void

    var body: some View {
        CompletionScaffold(mascot: .pose(.book), title: L.s(.readingComplete)) {
            VStack(spacing: expanded ? 24 : 14) {
                RewardRow(
                    icon: "🕐",
                    color: GeniColor.green,
                    label: L.s(.readingTime),
                    value: formattedTime(session.readingTimeSeconds)
                )

                RewardRow(
                    icon: "🪙",
                    color: GeniColor.yellow,
                    label: L.s(.coinsEarned),
                    value: "+\(session.coinsEarned)"
                )

                RewardRow(
                    icon: "⚡",
                    color: GeniColor.cyan,
                    label: L.s(.xpEarned),
                    value: "+50"
                )

                RewardRow(
                    icon: "🔥",
                    color: GeniColor.orange,
                    label: L.s(.streak),
                    value: "\(rewards.streakCount) \(rewards.streakCount == 1 ? L.s(.day) : L.s(.days))"
                )
            }
            .completionCard()

            if bonusAwarded {
                DailyBonusCard(coins: bonusCoins, playsHaptics: false)
            }
        } actions: {
            CompletionButton(title: L.s(.done), color: GeniColor.green, identifier: "readingComplete.done", action: onContinue)
        }
        .task {
            do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
            HapticManager.coinRipple(count: session.coinsEarned + bonusCoins)
        }
        .onAppear { HapticManager.correctAnswer() }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
