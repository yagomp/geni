import SwiftUI

struct MissionCompleteView: View {
    let mathStars: Int
    let mathCoins: Int
    let mathXP: Int
    let readingCoins: Int
    let bonusCoins: Int
    let rewards: RewardState
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var showConfetti = false
    @State private var starsBounce = 0
    @State private var showBonus = false

    private var totalCoins: Int {
        mathCoins + readingCoins + bonusCoins
    }

    var body: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Text("🎉")
                        .font(.system(size: iPadScale.value(64)))
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                    Text(L.s(.missionComplete))
                        .font(.system(size: iPadScale.value(32), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Text(star <= mathStars ? "⭐" : "☆")
                                .font(.system(size: 28))
                                .foregroundStyle(star <= mathStars ? GeniColor.yellow : .gray.opacity(0.3))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Text("➕")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(GeniColor.blue)
                                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))

                            Text(L.s(.mathDone))
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(GeniColor.border)

                            Spacer()

                            Text("+\(mathCoins) 🪙")
                                .font(.system(.headline, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                        }

                        Rectangle()
                            .fill(GeniColor.border.opacity(0.1))
                            .frame(height: 2)

                        HStack(spacing: 12) {
                            Text("📖")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(GeniColor.green)
                                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))

                            Text(L.s(.readingDone2))
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(GeniColor.border)

                            Spacer()

                            Text("+\(readingCoins) 🪙")
                                .font(.system(.headline, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                        }

                        if bonusCoins > 0 {
                            Rectangle()
                                .fill(GeniColor.border.opacity(0.1))
                                .frame(height: 2)

                            HStack(spacing: 12) {
                                Text("✨")
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(GeniColor.yellow)
                                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))

                                Text(L.s(.bonusEarned))
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(GeniColor.border)

                                Spacer()

                                Text("+\(bonusCoins) 🪙")
                                    .font(.system(.headline, design: .rounded, weight: .black))
                                    .foregroundStyle(GeniColor.yellow)
                            }
                        }

                        Rectangle()
                            .fill(GeniColor.border)
                            .frame(height: 3)

                        HStack {
                            Text(L.s(.total))
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)

                            Spacer()

                            Text("+\(totalCoins) 🪙")
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                        }
                    }
                    .padding(20)
                    .brutalistCard(color: GeniColor.card)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5).delay(0.5), value: appeared)

                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("🔥")
                                .font(.title2)
                                .foregroundStyle(GeniColor.orange)
                            Text("\(rewards.streakCount)")
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                            Text(rewards.streakCount == 1 ? L.s(.day) : L.s(.days))
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .brutalistCard(color: GeniColor.card, borderWidth: 3)

                        VStack(spacing: 4) {
                            Text("⭐")
                                .font(.title2)
                                .foregroundStyle(GeniColor.yellow)
                            Text("\(mathStars)/5")
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                            Text(L.s(.stars))
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .brutalistCard(color: GeniColor.card, borderWidth: 3)

                        VStack(spacing: 4) {
                            Text("🪙")
                                .font(.title2)
                                .foregroundStyle(GeniColor.yellow)
                            Text("\(rewards.coins)")
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(GeniColor.border)
                            Text(L.s(.coins))
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .brutalistCard(color: GeniColor.card, borderWidth: 3)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5).delay(0.7), value: appeared)

                    Button {
                        HapticManager.impact(.medium)
                        onContinue()
                    } label: {
                        Text(L.s(.done))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrutalistButton(color: GeniColor.blue))
                    .padding(.horizontal, 12)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.9), value: appeared)

                    Spacer().frame(height: iPadScale.value(40))
                }
                .padding(.horizontal, iPadScale.padding)
                .foregroundStyle(.black)
            }
        }
        .onAppear {
            appeared = true
            HapticManager.notification(.success)
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                starsBounce += 1
                showConfetti = true
            }
        }
    }
}
