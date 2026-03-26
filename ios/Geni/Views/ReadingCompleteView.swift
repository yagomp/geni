import SwiftUI

struct ReadingCompleteView: View {
    let session: ReadingSession
    let rewards: RewardState
    let bonusAwarded: Bool
    let bonusCoins: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    Text("📖")
                        .font(.system(size: 56))
                        .foregroundStyle(GeniColor.green)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                    Text(L.s(.readingComplete))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                    VStack(spacing: 16) {
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
                    .padding(20)
                    .brutalistCard(color: GeniColor.card)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5).delay(0.4), value: appeared)

                    if bonusAwarded {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("✨")
                                    .font(.title2)
                                Text(L.s(.dailyBonusTitle))
                                    .font(.system(.title3, design: .rounded, weight: .black))
                                    .foregroundStyle(GeniColor.border)
                            }

                            Text(L.s(.dailyBonusDesc))
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Text("🪙")
                                        .foregroundStyle(GeniColor.yellow)
                                    Text("+\(bonusCoins)")
                                        .font(.system(.headline, design: .rounded, weight: .black))
                                        .foregroundStyle(GeniColor.border)
                                }

                                HStack(spacing: 4) {
                                    Text("⚡")
                                    Text("+30 XP")
                                        .font(.system(.headline, design: .rounded, weight: .black))
                                        .foregroundStyle(GeniColor.border)
                                }
                            }
                        }
                        .padding(20)
                        .brutalistCard(color: GeniColor.yellow.opacity(0.1))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 40)
                        .animation(.spring(response: 0.5).delay(0.6), value: appeared)
                    }

                    Text(L.s(.greatJob))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.7), value: appeared)

                    Button {
                        HapticManager.impact(.medium)
                        onContinue()
                    } label: {
                        Text(L.s(.done))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrutalistButton(color: GeniColor.green))
                    .padding(.horizontal, 12)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.9), value: appeared)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .foregroundStyle(.black)
            }
        }
        .onAppear {
            appeared = true
            HapticManager.notification(.success)
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                showConfetti = true
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
