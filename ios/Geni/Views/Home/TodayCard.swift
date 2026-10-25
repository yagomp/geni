import SwiftUI

/// Two pictures and one next action. Every state keeps the same row and action positions.
struct TodayCard: View {
    let summary: TodaySummary
    @Environment(\.geniExpandedLayout) private var expanded
    var compact = false
    let perform: (TodaySummary.Action) -> Void

    var body: some View {
        VStack(spacing: expanded ? (compact ? 16 : 24) : (compact ? 12 : 16)) {
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
                        .frame(width: 1, height: expanded ? 200 : 112)
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
                    .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                    .foregroundStyle(tint.readableText)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: expanded ? 88 : (compact ? 56 : 60))
                    .background(tint, in: GeniShape())
                    .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                    .background(GeniShape().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .buttonStyle(KidPressStyle())
                .accessibilityIdentifier(action.identifier)
            } else if let headline = summary.headlineKey {
                Text("🎉 \(L.s(headline))")
                    .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: expanded ? 88 : (compact ? 56 : 60))
            }
        }
        .padding(expanded ? (compact ? 16 : 24) : (compact ? 12 : 16))
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
    @Environment(\.geniExpandedLayout) private var expanded
    var compact = false

    var body: some View {
        VStack(spacing: expanded ? (compact ? 6 : 10) : 4) {
            Text(emoji)
                .font(.system(size: expanded ? (compact ? 88 : 128) : (compact ? 72 : 80)))
                .frame(width: expanded ? (compact ? 112 : 152) : 88, height: expanded ? (compact ? 100 : 148) : (compact ? 80 : 88))
                .overlay(alignment: .topTrailing) {
                    if state == .done {
                        SelectionCheckDot()
                    }
                }

            Text(title)
                .font(.system(expanded ? .title : .title3, design: .rounded, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: expanded ? (compact ? 32 : 36) : 24)

            status
                .font(.system(expanded ? .title3 : .subheadline, design: .rounded, weight: .heavy))
                .frame(height: expanded ? (compact ? 32 : 44) : 32)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityStatus)
    }

    @ViewBuilder private var status: some View {
        if state == .done {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: expanded ? 32 : 24, weight: .black))
                .foregroundStyle(GeniColor.green.deep())
        } else if let progress {
            VStack(spacing: 4) {
                ProgressView(value: Double(progress), total: 20)
                    .tint(tint)
                    .frame(width: expanded ? 148 : 88)
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
