import SwiftUI

struct ChapterCompleteView: View {
    let chapter: ChapterProgress
    let rewards: RewardState
    let xpEarned: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var starsBounce = 0
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

                    Text(chapter.stars == 5 ? L.s(.perfectScore) : L.s(.chapterComplete))
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= chapter.stars ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= chapter.stars ? GeniColor.yellow : .gray.opacity(0.3))
                                .symbolEffect(.bounce, value: starsBounce)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                    VStack(spacing: 16) {
                        RewardRow(
                            icon: "checkmark.circle.fill",
                            color: GeniColor.green,
                            label: L.s(.correct),
                            value: "\(chapter.correctCount)/\(chapter.exerciseResults.count)"
                        )

                        RewardRow(
                            icon: "dollarsign.circle.fill",
                            color: GeniColor.yellow,
                            label: L.s(.coinsEarned),
                            value: "+\(chapter.coinsEarned)"
                        )

                        RewardRow(
                            icon: "bolt.circle.fill",
                            color: GeniColor.cyan,
                            label: L.s(.xpEarned),
                            value: "+\(xpEarned)"
                        )

                        RewardRow(
                            icon: "flame.fill",
                            color: GeniColor.orange,
                            label: L.s(.streak),
                            value: "\(rewards.streakCount) \(rewards.streakCount == 1 ? L.s(.day) : L.s(.days))"
                        )
                    }
                    .padding(20)
                    .brutalistCard(color: GeniColor.card)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5).delay(0.5), value: appeared)

                    Text(L.s(.greatJob))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                        .opacity(appeared ? 1 : 0)
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

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
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

struct RewardRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(label)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(GeniColor.border)

            Spacer()

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(color)
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
