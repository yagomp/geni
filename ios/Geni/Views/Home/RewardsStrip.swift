import SwiftUI

struct RewardsStrip: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let rewards: RewardState
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    CoinIcon(size: expanded ? 40 : 28)
                    Text("\(rewards.coins)")
                        .accessibilityIdentifier("home.coins")
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("🔥").accessibilityHidden(true)
                    Text("\(rewards.streakCount)")
                }
                .accessibilityLabel("\(L.s(.streak)), \(rewards.streakCount)")

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("⭐").accessibilityHidden(true)
                    Text("\(rewards.level)")
                }
                .accessibilityLabel("\(L.s(.level)), \(rewards.level)")

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .black))
                    .accessibilityHidden(true)
            }
            .font(.system(size: expanded ? 36 : 28, weight: .black, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: expanded ? 88 : 64)
            .brutalistCard(color: GeniColor.card, borderWidth: 3)
        }
        .buttonStyle(KidPressStyle())
        .accessibilityIdentifier("home.rewards")
    }
}
