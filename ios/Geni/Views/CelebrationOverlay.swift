import SwiftUI

struct LevelUpOverlay: View {
    let level: Int
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var particleBurst = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Text("⬆️")
                    .font(.system(size: 72))
                    .foregroundStyle(GeniColor.purple)
                    .symbolEffect(.bounce, value: particleBurst)

                Text(L.s(.levelUp))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("\(L.s(.level)) \(level)")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.purple)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(GeniColor.purple.opacity(0.15))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))

                Button {
                    dismiss()
                } label: {
                    Text(L.s(.awesome))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrutalistButton(color: GeniColor.purple))
                .padding(.horizontal, 24)
            }
            .padding(32)
            .frame(maxWidth: 320)
            .background(GeniColor.card)
            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 4))
            .background(Rectangle().fill(GeniColor.border).offset(x: 6, y: 6))
            .scaleEffect(appeared ? 1 : 0.3)
            .opacity(appeared ? 1 : 0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
        .onAppear {
            appeared = true
            HapticManager.levelUp()
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                particleBurst = true
            }
        }
    }

    private func dismiss() {
        appeared = false
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }
}

struct BadgeUnlockOverlay: View {
    let badge: Badge
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var iconBounce = 0
    @State private var particles: [CelebrationParticle] = []
    @State private var useFireworks = Bool.random()

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Celebration particles
            GeometryReader { geo in
                ForEach(particles) { p in
                    Group {
                        if useFireworks {
                            Circle()
                                .fill(p.color)
                                .frame(width: p.size, height: p.size)
                                .shadow(color: p.color.opacity(0.6), radius: 4)
                        } else {
                            Rectangle()
                                .fill(p.color)
                                .frame(width: p.size * 0.6, height: p.size * 1.4)
                                .rotationEffect(.degrees(p.rotation))
                        }
                    }
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                Text(L.s(.newBadge))
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)

                Text(badge.icon)
                    .font(.system(size: 64))
                    .frame(width: 100, height: 100)
                    .background(badge.color.opacity(0.15))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))

                VStack(spacing: 4) {
                    Text(L.s(badge.titleKey))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text(L.s(badge.descriptionKey))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                }

                Button {
                    dismiss()
                } label: {
                    Text(L.s(.awesome))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrutalistButton(color: badge.color))
                .padding(.horizontal, 24)
            }
            .padding(32)
            .frame(maxWidth: 320)
            .background(GeniColor.card)
            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 4))
            .background(Rectangle().fill(GeniColor.border).offset(x: 6, y: 6))
            .scaleEffect(appeared ? 1 : 0.3)
            .opacity(appeared ? 1 : 0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
        .onAppear {
            appeared = true
            HapticManager.badgeUnlock()
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                iconBounce += 1
                launchCelebration()
            }
        }
    }

    private func dismiss() {
        appeared = false
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }

    private func launchCelebration() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, GeniColor.yellow, GeniColor.green]

        if useFireworks {
            // Fireworks: burst from 2-3 center points
            let burstCount = Int.random(in: 2...3)
            for _ in 0..<burstCount {
                let cx = CGFloat.random(in: screenW * 0.2...screenW * 0.8)
                let cy = CGFloat.random(in: screenH * 0.15...screenH * 0.4)
                for i in 0..<20 {
                    let angle = Double.random(in: 0...(2 * .pi))
                    let speed = CGFloat.random(in: 80...200)
                    let dx = cos(angle) * speed
                    let dy = sin(angle) * speed
                    let p = CelebrationParticle(
                        x: cx, y: cy,
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 6...12),
                        rotation: 0, opacity: 1
                    )
                    particles.append(p)
                    let idx = particles.count - 1
                    let delay = Double(i) * 0.02
                    Task {
                        try? await Task.sleep(for: .seconds(delay))
                        await animateParticle(idx, dx: dx, dy: dy + 100)
                    }
                }
            }
        } else {
            // Confetti: fall from top
            for i in 0..<40 {
                let p = CelebrationParticle(
                    x: CGFloat.random(in: 0...screenW),
                    y: -20,
                    color: colors.randomElement()!,
                    size: CGFloat.random(in: 8...14),
                    rotation: Double.random(in: 0...360),
                    opacity: 1
                )
                particles.append(p)
                let idx = particles.count - 1
                let delay = Double(i) * 0.05
                Task {
                    try? await Task.sleep(for: .seconds(delay))
                    await animateConfetti(idx, screenH: screenH)
                }
            }
        }
    }

    @MainActor
    private func animateParticle(_ idx: Int, dx: CGFloat, dy: CGFloat) {
        guard idx < particles.count else { return }
        withAnimation(.easeOut(duration: 1.2)) {
            particles[idx].x += dx
            particles[idx].y += dy
            particles[idx].opacity = 0
        }
    }

    @MainActor
    private func animateConfetti(_ idx: Int, screenH: CGFloat) {
        guard idx < particles.count else { return }
        withAnimation(.easeIn(duration: Double.random(in: 1.5...2.5))) {
            particles[idx].y = screenH + 40
            particles[idx].x += CGFloat.random(in: -60...60)
            particles[idx].rotation += Double.random(in: 180...720)
            particles[idx].opacity = 0
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var rotation: Double
    var opacity: Double
}
