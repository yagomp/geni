import SwiftUI

struct ChapterCompleteView: View {
    let chapter: ChapterProgress
    let rewards: RewardState
    let xpEarned: Int
    var bonusCoins = 0
    let onContinue: () -> Void

    var body: some View {
        GeniLearningLayout {
            ChapterCompleteViewLayout(chapter: chapter, rewards: rewards, xpEarned: xpEarned, bonusCoins: bonusCoins, onContinue: onContinue)
        }
    }
}

private struct ChapterCompleteViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let chapter: ChapterProgress
    let rewards: RewardState
    let xpEarned: Int
    let bonusCoins: Int
    let onContinue: () -> Void

    var body: some View {
        CompletionScaffold(mascot: .cheer, title: chapter.stars == 5 ? L.s(.perfectScore) : L.s(.chapterComplete)) {
            CompletionStars(stars: chapter.stars)

            VStack(spacing: expanded ? 24 : 14) {
                RewardRow(
                    icon: "✅",
                    color: GeniColor.green,
                    label: L.s(.correct),
                    value: "\(chapter.correctCount)/\(chapter.completedExerciseCount)"
                )

                RewardRow(
                    icon: "🪙",
                    color: GeniColor.yellow,
                    label: L.s(.coinsEarned),
                    value: "+\(chapter.coinsEarned)"
                )

                RewardRow(
                    icon: "⚡",
                    color: GeniColor.cyan,
                    label: L.s(.xpEarned),
                    value: "+\(xpEarned)"
                )

                RewardRow(
                    icon: "🔥",
                    color: GeniColor.orange,
                    label: L.s(.streak),
                    value: "\(rewards.streakCount) \(rewards.streakCount == 1 ? L.s(.day) : L.s(.days))"
                )
            }
            .completionCard()

            if bonusCoins > 0 {
                DailyBonusCard(coins: bonusCoins, playsHaptics: false)
            }
        } actions: {
            CompletionButton(title: L.s(.done), color: GeniColor.blue, identifier: "chapterComplete.done", action: onContinue)
        }
        .task {
            do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
            HapticManager.coinRipple(count: chapter.coinsEarned + bonusCoins)
        }
        .onAppear { HapticManager.correctAnswer() }
    }
}

struct RewardRow: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(expanded ? .largeTitle : .title2)
                .frame(width: expanded ? 48 : 32)

            Text(label)
                .font(.system(expanded ? .title2 : .body, design: .rounded, weight: .semibold))
                .foregroundStyle(GeniColor.border)

            Spacer()

            Text(value)
                .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.soft(0.35))
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width - 6,
                    y: particle.y * size.height - 6,
                    width: 12, height: 12
                )
                context.fill(
                    Path(CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)),
                    with: .color(particle.color)
                )
            }
        }
        .onAppear {
            particles = (0..<40).map { _ in
                ConfettiParticle(
                    x: Double.random(in: 0...1),
                    y: Double.random(in: -0.5...0),
                    color: [GeniColor.yellow, GeniColor.blue, GeniColor.pink, GeniColor.green, GeniColor.purple, GeniColor.orange].randomElement()!,
                    isCircle: Bool.random()
                )
            }
            withAnimation(.easeIn(duration: 2.5)) {
                for i in particles.indices {
                    particles[i].y = Double.random(in: 1.2...1.8)
                    particles[i].x += Double.random(in: -0.3...0.3)
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let color: Color
    let isCircle: Bool
}
