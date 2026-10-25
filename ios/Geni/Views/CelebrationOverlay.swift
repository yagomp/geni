import SwiftUI

private extension View {
    /// Popup card: 4pt outline, 6pt offset shadow, shape follows the profile's corner style.
    func popupCard() -> some View {
        self
            .padding(24)
            .frame(maxWidth: 320)
            .background(GeniColor.card)
            .clipShape(GeniShape())
            .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 4))
            .background(GeniShape().fill(GeniColor.border).offset(x: 6, y: 6))
            .compositingGroup()
    }

    /// Slow-in entrance: scale + fade, or fade only under Reduce Motion.
    func popupEntrance(appeared: Bool, reduceMotion: Bool) -> some View {
        self
            .scaleEffect(reduceMotion || appeared ? 1 : 0.3)
            .opacity(appeared ? 1 : 0)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6), value: appeared)
    }
}

struct LevelUpOverlay: View {
    let level: Int
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var medalScale: CGFloat = 1

    var body: some View {
        ZStack {
            GeniColor.purple.soft(0.2)
                .opacity(appeared ? 0.94 : 0)
                .animation(.easeOut(duration: 0.2), value: appeared)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                LevelMedallion(level: level, size: 120)
                    .scaleEffect(medalScale)

                Text(L.s(.levelUp))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text(L.s(.awesome))
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(BrutalistButton(color: GeniColor.purple))
                .accessibilityIdentifier("levelUp.dismiss")
            }
            .popupCard()
            .popupEntrance(appeared: appeared, reduceMotion: reduceMotion)
        }
        .onAppear {
            appeared = true
            HapticManager.levelUp()
            guard !reduceMotion else { return }
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { medalScale = 1.15 }
                try? await Task.sleep(for: .seconds(0.2))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { medalScale = 1 }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var medalScale: CGFloat = 1
    @State private var particles: [CelebrationParticle] = []
    @State private var useFireworks = Bool.random()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                badge.color.soft(0.25)
                    .opacity(appeared ? 0.94 : 0)
                    .animation(.easeOut(duration: 0.2), value: appeared)
                    .onTapGesture { dismiss() }

                ForEach(particles) { p in
                    Group {
                        if useFireworks {
                            Circle()
                                .fill(p.color)
                                .overlay(Circle().stroke(GeniColor.border, lineWidth: 1.5))
                                .frame(width: p.size, height: p.size)
                        } else {
                            GeniShape(scale: 0.2)
                                .fill(p.color)
                                .overlay(GeniShape(scale: 0.2).stroke(GeniColor.border, lineWidth: 1.5))
                                .frame(width: p.size * 0.6, height: p.size * 1.4)
                                .rotationEffect(.degrees(p.rotation))
                        }
                    }
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 16) {
                    BadgeMedallion(badge: badge, size: 120, earned: true)
                        .scaleEffect(medalScale)
                        .padding(.bottom, 8)

                    Text(L.s(badge.titleKey))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .multilineTextAlignment(.center)

                    Text(L.s(badge.descriptionKey))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(GeniColor.border)
                        .multilineTextAlignment(.center)

                    Button {
                        dismiss()
                    } label: {
                        Text(L.s(.awesome))
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(BrutalistButton(color: badge.color))
                    .accessibilityIdentifier("badge.dismiss")
                    .padding(.top, 8)
                }
                .popupCard()
                .popupEntrance(appeared: appeared, reduceMotion: reduceMotion)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                appeared = true
                HapticManager.badgeUnlock()
                guard !reduceMotion else { return }
                let size = geo.size
                Task {
                    try? await Task.sleep(for: .seconds(0.3))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { medalScale = 1.15 }
                    launchCelebration(in: size)
                    try? await Task.sleep(for: .seconds(0.2))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { medalScale = 1 }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func dismiss() {
        appeared = false
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }

    private func launchCelebration(in size: CGSize) {
        let screenW = size.width
        let screenH = size.height
        let colors: [Color] = [GeniColor.pink, GeniColor.orange, GeniColor.yellow, GeniColor.green, GeniColor.blue, GeniColor.purple, GeniColor.cyan]

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
                        animateParticle(idx, dx: dx, dy: dy + 100)
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
                    animateConfetti(idx, screenH: screenH)
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
