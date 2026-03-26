import SwiftUI

struct ReadingModeSelectionView: View {
    let profile: ChildProfile
    let readingText: ReadingText
    let onSelectMode: (ReadingMode) -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button {
                        HapticManager.selection()
                        onBack()
                    } label: {
                        Text("◀️").font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(GeniColor.card)
                            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 8) {
                    Text("📖")
                        .font(.system(size: 48))
                        .foregroundStyle(GeniColor.green)

                    Text(L.s(.readingTime))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)

                    Text(readingText.title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)

                    let mins = ReadingText.targetReadingSeconds(for: profile.age) / 60
                    Text("\(mins) \(L.s(.minutes))")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GeniColor.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(GeniColor.green.opacity(0.15))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(.spring(response: 0.5), value: appeared)

                Spacer()

                VStack(spacing: 12) {
                    ReadingModeButton(
                        title: L.s(.readByMyself),
                        subtitle: L.s(.readBySelfDesc),
                        icon: "👁️",
                        color: GeniColor.blue
                    ) {
                        HapticManager.impact(.medium)
                        onSelectMode(.readByMyself)
                    }

                    ReadingModeButton(
                        title: L.s(.readToMe),
                        subtitle: L.s(.readToMeDesc),
                        icon: "🔊",
                        color: GeniColor.purple
                    ) {
                        HapticManager.impact(.medium)
                        onSelectMode(.readToMe)
                    }

                    ReadingModeButton(
                        title: L.s(.listenToMeRead),
                        subtitle: L.s(.listenToMeDesc),
                        icon: "🎤",
                        color: GeniColor.orange
                    ) {
                        HapticManager.impact(.medium)
                        onSelectMode(.listenToMeRead)
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                Spacer()
            }
            .padding(.top, 20)
            .foregroundStyle(.black)
        }
        .onAppear { appeared = true }
    }
}

struct ReadingModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.black)
                }

                Spacer()

                Text("▶️").font(.system(size: 16))
            }
            .padding(16)
            .brutalistCard(color: GeniColor.card)
        }
    }
}
