import SwiftUI

/// Math and reading both done today: +coins and +30 XP. Shown by whichever completion screen came second.
struct DailyBonusCard: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let coins: Int
    var playsHaptics = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("✨")
                    .font(.title2)
                Text(L.s(.dailyBonusTitle))
                    .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)
            }

            Text(L.s(.dailyBonusDesc))
                .font(.system(expanded ? .title3 : .subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("🪙")
                        .foregroundStyle(GeniColor.yellow)
                    Text("+\(coins)")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }

                HStack(spacing: 4) {
                    Text("⚡")
                    Text("+30 \(L.s(.xp))")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
            }
        }
        .padding(expanded ? 32 : 20)
        .softSurface(GeniColor.card)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dailyBonus")
        .task {
            guard playsHaptics else { return }
            do { try await Task.sleep(for: .seconds(0.6)) } catch { return }
            HapticManager.coinRipple(count: coins)
        }
    }
}
