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
                Image(systemName: "arrow.up.circle.fill")
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

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Text(L.s(.newBadge))
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)

                Image(systemName: badge.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(badge.color)
                    .frame(width: 100, height: 100)
                    .background(badge.color.opacity(0.15))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                    .symbolEffect(.bounce, value: iconBounce)

                VStack(spacing: 4) {
                    Text(L.s(badge.titleKey))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text(L.s(badge.descriptionKey))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
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
