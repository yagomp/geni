import SwiftUI

struct ReadingModeSelectionView: View {
    let profile: ChildProfile
    let readingText: ReadingText
    let onSelectMode: (ReadingMode) -> Void
    let onBack: () -> Void

    var body: some View {
        GeniLearningLayout {
            ReadingModeSelectionViewLayout(profile: profile, readingText: readingText, onSelectMode: onSelectMode, onBack: onBack)
        }
    }
}

private struct ReadingModeSelectionViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let profile: ChildProfile
    let readingText: ReadingText
    let onSelectMode: (ReadingMode) -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: expanded ? 32 : 24) {
                HStack {
                    Button {
                        HapticManager.selection()
                        onBack()
                    } label: {
                        Text("◀️").font(.system(size: expanded ? 30 : 20))
                            .frame(width: expanded ? 64 : 44, height: expanded ? 64 : 44)
                            .background(GeniColor.card)
                            .clipShape(GeniShape())
                            .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                    }
                    .accessibilityIdentifier("readingMode.back")
                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 8) {
                    Text("📖")
                        .font(.system(size: expanded ? 72 : 48))
                        .foregroundStyle(GeniColor.green)

                    Text(L.s(.readingTime))
                        .font(.system(size: expanded ? 48 : 32, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)

                    Text(readingText.title)
                        .font(.system(expanded ? .title : .title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)

                    let mins = ReadingText.targetReadingSeconds(for: profile.age) / 60
                    Text("\(mins) \(L.s(.minutes))")
                        .font(.system(expanded ? .title3 : .subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GeniColor.border)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(GeniColor.green.soft(0.2))
                        .clipShape(GeniShape())
                        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 2))
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(.spring(response: 0.5), value: appeared)

                Spacer()

                VStack(spacing: 12) {
                    ReadingModeButton(
                        title: L.s(.readToMe),
                        subtitle: L.s(.readToMeDesc),
                        icon: "🔊",
                        color: GeniColor.purple,
                        identifier: "readingMode.readToMe"
                    ) {
                        HapticManager.impact(.medium)
                        onSelectMode(.readToMe)
                    }

                    ReadingModeButton(
                        title: L.s(.listenToMeRead),
                        subtitle: L.s(.listenToMeDesc),
                        icon: "🎤",
                        color: GeniColor.orange,
                        identifier: "readingMode.listenToMe"
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
            .frame(maxWidth: expanded ? 840 : .infinity)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.black)
        }
        .onAppear { appeared = true }
    }
}

struct ReadingModeButton: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var identifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                Text(icon)
                    .font(expanded ? .largeTitle : .title2)
                    .frame(width: expanded ? 80 : 48, height: expanded ? 80 : 48)
                    .background(color)
                    .clipShape(GeniShape())
                    .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(expanded ? .title : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)

                    if !expanded {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.black)
                    }
                }

                Spacer()

                Text("▶️").font(.system(size: 16))
            }
            .padding(expanded ? 28 : 16)
            .brutalistCard(color: GeniColor.card)
        }
        .accessibilityIdentifier(identifier ?? "")
    }
}
