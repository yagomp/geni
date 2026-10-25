import SwiftUI

/// Two pictures and one next action. Every state keeps the same row and action positions.
struct TodayCard: View {
    let summary: TodaySummary
    var compact = false
    let perform: (TodaySummary.Action) -> Void

    var body: some View {
        VStack(spacing: compact ? 12 : 16) {
            HStack(spacing: 12) {
                TaskTile(
                    emoji: "🔢",
                    title: L.s(.mathProgress),
                    state: summary.math,
                    tint: GeniColor.blue,
                    progress: summary.mathProgress,
                    compact: compact
                )

                if let reading = summary.reading {
                    Rectangle()
                        .fill(GeniColor.lightGray)
                        .frame(width: 1, height: 112)
                        .accessibilityHidden(true)

                    TaskTile(
                        emoji: "📖",
                        title: L.s(.readingProgress),
                        state: reading,
                        tint: GeniColor.green,
                        isBonus: summary.readingIsOptional,
                        compact: compact
                    )
                }
            }
            .frame(maxHeight: .infinity)

            if let action = summary.action {
                let tint = action.isReading ? GeniColor.green : GeniColor.blue
                Button {
                    HapticManager.impact(.medium)
                    perform(action)
                } label: {
                    HStack(spacing: 8) {
                        Text(action.isReading ? "📖" : "🔢")
                            .accessibilityHidden(true)
                        Text(L.s(action.labelKey))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(tint.readableText)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 56 : 60)
                    .background(tint, in: GeniShape())
                    .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                    .background(GeniShape().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .buttonStyle(KidPressStyle())
                .accessibilityIdentifier(action.identifier)
            } else if let headline = summary.headlineKey {
                Text("🎉 \(L.s(headline))")
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 56 : 60)
            }
        }
        .padding(compact ? 12 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .brutalistCard(color: GeniColor.card, borderWidth: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.today")
    }
}

/// A picture, a word and a status; no coloured panel, outline or connecting line.
private struct TaskTile: View {
    let emoji: String
    let title: String
    let state: TodaySummary.NodeState
    let tint: Color
    var progress: Int? = nil
    var isBonus = false
    var compact = false

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: compact ? 72 : 80))
                .frame(width: 88, height: compact ? 80 : 88)
                .overlay(alignment: .topTrailing) {
                    if state == .done {
                        SelectionCheckDot()
                    }
                }

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: 24)

            status
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityStatus)
    }

    @ViewBuilder private var status: some View {
        if state == .done {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(GeniColor.green.deep())
        } else if let progress {
            VStack(spacing: 4) {
                ProgressView(value: Double(progress), total: 20)
                    .tint(tint)
                    .frame(width: 88)
                Text("\(progress)/20").monospacedDigit()
            }
        } else if isBonus {
            Text("⭐ \(L.s(.bonusLabel))")
                .foregroundStyle(GeniColor.orange.deep())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } else {
            Color.clear
        }
    }

    private var accessibilityStatus: String {
        if state == .done { return L.s(.completed) }
        if let progress { return "\(progress) \(L.s(.of20))" }
        let status = state == .current ? L.s(.topicCurrent) : L.s(.next)
        return isBonus ? "\(status), \(L.s(.optionalLabel))" : status
    }
}
