import SwiftUI

/// Today's tasks as big picture bubbles straight on the background, each its own ▶︎ start,
/// so the child picks the order. A single task keeps the same bubble size, centred.
struct TodayCard: View {
    let summary: TodaySummary
    @Environment(\.geniExpandedLayout) private var expanded
    var compact = false
    let perform: (TodaySummary.Action) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: expanded ? 56 : 28) {
            TaskBubble(
                emoji: "🔢",
                title: L.s(.mathProgress),
                state: summary.math,
                action: summary.mathAction,
                tint: GeniColor.blue,
                progress: (summary.mathProgress ?? 0, summary.chapterLength),
                detail: summary.mathTopic,
                compact: compact,
                perform: perform
            )

            if let reading = summary.reading {
                TaskBubble(
                    emoji: "📖",
                    title: L.s(.readingProgress),
                    state: reading,
                    action: summary.readingAction,
                    tint: GeniColor.green,
                    // Reading is saved when finished, so the bar shows the goal until then
                    progress: (0, summary.readingMinutes),
                    unit: "min",
                    isBonus: summary.readingIsOptional,
                    compact: compact,
                    perform: perform
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.today")
    }
}

/// A big tinted bubble with the task's picture and a ▶︎ (or ✓ when done) badge, its name, and progress.
private struct TaskBubble: View {
    let emoji: String
    let title: String
    let state: TodaySummary.NodeState
    let action: TodaySummary.Action?
    let tint: Color
    var progress: (done: Int, total: Int)? = nil
    /// Shown after the count, e.g. "min".
    var unit: String? = nil
    /// One small line under the progress: today's topic (math) or ⭐ Bonus (optional reading).
    var detail: String? = nil
    var isBonus = false
    @Environment(\.geniExpandedLayout) private var expanded
    var compact = false
    let perform: (TodaySummary.Action) -> Void

    private var size: CGFloat { expanded ? (compact ? 168 : 208) : (compact ? 112 : 136) }

    var body: some View {
        if let action {
            Button {
                HapticManager.impact(.medium)
                perform(action)
            } label: {
                content
            }
            .buttonStyle(KidPressStyle())
            .accessibilityIdentifier(action.identifier)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: expanded ? 16 : 10) {
            Text(emoji)
                // The picture is the button: big, no tile behind it; done tasks step back a little
                .font(.system(size: size * 0.78))
                .shadow(color: GeniColor.border.opacity(0.18), radius: 8, x: 0, y: 6)
                .opacity(state == .done ? 0.55 : 1)
                .frame(width: size, height: size)
                .overlay(alignment: .bottomTrailing) { badge.offset(x: -size * 0.02, y: -size * 0.02) }

            Text(title)
                .font(.system(expanded ? .title : .title3, design: .rounded, weight: .heavy))
                .foregroundStyle(GeniColor.border)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            status
                .frame(width: size + 16, height: expanded ? 28 : 20)

            let bonus = isBonus && state != .done
            Text(bonus ? "⭐ \(L.s(.bonusLabel))" : detail ?? " ")
                .font(.system(expanded ? .title3 : .footnote, design: .rounded, weight: bonus ? .heavy : .semibold))
                .foregroundStyle(bonus ? GeniColor.orange.deep() : GeniColor.border.opacity(0.55))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .frame(width: size + 16, height: expanded ? 56 : 36, alignment: .top)
        }
        .frame(width: size + 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(action.map { L.s($0.labelKey) } ?? title)
        .accessibilityValue(accessibilityStatus)
    }

    @ViewBuilder private var badge: some View {
        let diameter = size * 0.36
        if state == .done {
            Image(systemName: "checkmark")
                .font(.system(size: diameter * 0.42, weight: .black))
                .foregroundStyle(.white)
                .frame(width: diameter, height: diameter)
                .background(GeniColor.green, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 4))
        } else if action != nil {
            Image(systemName: "play.fill")
                .font(.system(size: diameter * 0.4, weight: .black))
                .foregroundStyle(.white)
                .offset(x: diameter * 0.04)
                .frame(width: diameter, height: diameter)
                .background(tint, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: tint.opacity(0.35), radius: 6, y: 3)
        }
    }

    /// Math: a bar and "3 / 20" until done. Reading: ⭐ Bonus when optional. Done: the whole count.
    @ViewBuilder private var status: some View {
        // Done shows a full bar, so finished and unfinished columns line up
        if let raw = progress {
            let progress = state == .done ? (done: raw.total, total: raw.total) : raw
            HStack(spacing: 6) {
                GeometryReader { geo in
                    GeniShape().fill(tint.soft(0.2))
                        .overlay(alignment: .leading) {
                            GeniShape().fill(tint)
                                .frame(width: geo.size.width * CGFloat(progress.done) / CGFloat(max(progress.total, 1)))
                        }
                }
                .frame(height: expanded ? 12 : 8)
                Text("\(progress.done) / \(progress.total)" + (unit.map { " \($0)" } ?? ""))
                    .font(.system(expanded ? .title3 : .subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(tint.deep(0.2))
                    .monospacedDigit()
                    .fixedSize()
            }
        } else {
            Color.clear
        }
    }

    private var accessibilityStatus: String {
        if state == .done { return L.s(.completed) }
        if let progress { return "\(progress.done) / \(progress.total)" }
        return isBonus ? L.s(.optionalLabel) : ""
    }
}
