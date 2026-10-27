import SwiftUI

struct DataGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    @Environment(\.geniExerciseViewport) private var viewport
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        DataGameLayout(spacing: expanded ? 36 : 24, availableHeight: viewport.height) {
            GameQuestion(text: spec.prompt)
            if let payload = spec.payload as? TallyPayload {
                GameSceneCard { TallyChart(rows: payload.rows) }
                choices(payload.choices)
            } else if let payload = spec.payload as? BarPayload {
                GameSceneCard { BarChart(payload: payload) }
                choices(payload.choices)
            } else if let payload = spec.payload as? EstimatePayload {
                GameSceneCard { EstimatePicture(payload: payload) }
                choices(payload.choices)
            }
        }
    }

    private func choices(_ choices: [GameChoice]) -> some View {
        GameChoices(choices: choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
    }
}

/// Question, picture card, choices. The question and the choices keep their own height; the card
/// gets what is left of `availableHeight` (down to its own minimum, then the screen scrolls), and
/// the pictures size themselves to the height they are offered.
private struct DataGameLayout: Layout {
    var spacing: CGFloat
    /// Height the screen leaves for the whole game; 0 when unknown (the picture keeps its natural size).
    var availableHeight: CGFloat

    private func card(_ subviews: Subviews, width: CGFloat?, others: CGFloat) -> ProposedViewSize {
        guard availableHeight > 0, subviews.count == 3 else { return ProposedViewSize(width: width, height: nil) }
        let minimum = subviews[1].sizeThatFits(ProposedViewSize(width: width, height: 0)).height
        return ProposedViewSize(width: width, height: max(minimum, availableHeight - others - spacing * 2))
    }

    private func heights(_ proposal: ProposedViewSize, _ subviews: Subviews) -> [CGFloat] {
        let natural = ProposedViewSize(width: proposal.width, height: nil)
        var heights = subviews.map { $0.sizeThatFits(natural).height }
        if subviews.count == 3 {
            let others = heights[0] + heights[2]
            heights[1] = subviews[1].sizeThatFits(card(subviews, width: proposal.width, others: others)).height
        }
        return heights
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let heights = heights(proposal, subviews)
        let widest = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)).width }.max() ?? 0
        let height = heights.reduce(0, +) + spacing * CGFloat(max(subviews.count - 1, 0))
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        let heights = heights(ProposedViewSize(width: width, height: nil), subviews)
        var y = bounds.minY
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: heights[index]))
            y += heights[index] + spacing
        }
    }
}

/// Phone size × iPad scale, shared by the pictures below.
private func scaled(_ base: CGFloat, expanded: Bool) -> CGFloat {
    expanded ? base * 1.6 : iPadScale.value(base)
}

// MARK: Tally chart

/// One tally group: up to four upright strokes, the fifth drawn across them.
private struct TallyGroupShape: Shape {
    let count: Int
    let gap: CGFloat
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for i in 0..<min(count, 4) {
            let x = rect.minX + inset + CGFloat(i) * gap
            path.move(to: CGPoint(x: x, y: rect.minY + inset))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - inset))
        }
        if count >= 5 {
            path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.15))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.15))
        }
        return path
    }
}

private struct TallyMarks: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let count: Int
    var fit: CGFloat = 1

    var body: some View {
        let height = scaled(34, expanded: expanded) * fit
        let line = scaled(4, expanded: expanded)
        let gap = height * 0.4
        let groups = Array(repeating: 5, count: count / 5) + (count % 5 > 0 ? [count % 5] : [])
        HStack(spacing: gap * 0.7) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, size in
                let width = CGFloat(size == 5 ? 3 : size - 1) * gap + line
                TallyGroupShape(count: size, gap: gap, inset: line / 2)
                    .stroke(GeniColor.border, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .frame(width: width, height: height)
            }
        }
    }
}

private struct TallyChart: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let rows: [TallyRow]

    var body: some View {
        let natural = scaled(56, expanded: expanded)
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Rectangle().fill(GeniColor.lightGray).frame(height: 2)
                }
                // Rows share the height they are offered, from natural down to a readable minimum.
                GeometryReader { geo in
                    let fit = geo.size.height / natural
                    HStack(spacing: scaled(12, expanded: expanded)) {
                        Text(row.emoji)
                            .font(.system(size: scaled(36, expanded: expanded) * fit))
                            .frame(width: scaled(48, expanded: expanded))
                        TallyMarks(count: row.count, fit: fit)
                        Spacer(minLength: 0)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(minHeight: natural * 0.65, idealHeight: natural, maxHeight: natural)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rows.map { "\($0.emoji) \($0.count)" }.joined(separator: ", "))
    }
}

// MARK: Bar chart

private struct GridLines: Shape {
    let levels: [Int]
    let top: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for level in levels {
            let y = rect.maxY - rect.height * CGFloat(level) / CGFloat(top)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

private struct BarChart: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let payload: BarPayload
    private let colors = [GeniColor.blue, GeniColor.green, GeniColor.orange, GeniColor.pink]

    private func s(_ base: CGFloat) -> CGFloat { scaled(base, expanded: expanded) }

    var body: some View {
        let top = payload.axisMax
        let labelled = Array(stride(from: 0, through: top, by: 2))
        VStack(spacing: s(6)) {
            // The plot takes the height it is offered, from natural down to a readable minimum;
            // the emoji row under it keeps its own.
            GeometryReader { geo in
                let plotHeight = geo.size.height
                HStack(alignment: .top, spacing: s(6)) {
                    ZStack {
                        ForEach(labelled, id: \.self) { level in
                            Text("\(level)")
                                .font(.system(size: s(14), weight: .heavy, design: .rounded))
                                .foregroundStyle(GeniColor.border)
                                .position(x: s(13), y: plotHeight * (1 - CGFloat(level) / CGFloat(top)))
                        }
                    }
                    .frame(width: s(26), height: plotHeight)

                    ZStack(alignment: .bottom) {
                        GridLines(levels: Array(1...top), top: top)
                            .stroke(GeniColor.lightGray, lineWidth: 1.5)
                        GridLines(levels: Array(stride(from: 2, through: top, by: 2)), top: top)
                            .stroke(GeniColor.border.opacity(0.25), lineWidth: 1.5)
                        HStack(alignment: .bottom, spacing: s(12)) {
                            ForEach(Array(payload.bars.enumerated()), id: \.offset) { index, bar in
                                Rectangle()
                                    .fill(colors[index % colors.count])
                                    .overlay(Rectangle().stroke(GameStyle.hairline, lineWidth: 1.5))
                                    .frame(maxWidth: s(64))
                                    .frame(height: plotHeight * CGFloat(bar.value) / CGFloat(top))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, s(8))
                        Rectangle().fill(GeniColor.border).frame(height: 3)
                    }
                    .frame(height: plotHeight)
                }
            }
            .frame(minHeight: s(72), idealHeight: s(150), maxHeight: s(150))

            HStack(spacing: s(12)) {
                ForEach(Array(payload.bars.enumerated()), id: \.offset) { _, bar in
                    Text(bar.emoji)
                        .font(.system(size: s(34)))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.leading, s(26) + s(6) + s(8))
            .padding(.trailing, s(8))
        }
        .padding(.vertical, s(6))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(payload.bars.map { "\($0.emoji) \($0.value)" }.joined(separator: ", "))
    }
}

// MARK: Estimate

private struct EstimatePicture: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let payload: EstimatePayload

    private func s(_ base: CGFloat) -> CGFloat { scaled(base, expanded: expanded) }

    var body: some View {
        if let expression = payload.expression {
            Text(expression)
                .font(.system(size: s(54), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: s(110))
        } else {
            jar
        }
    }

    private var jar: some View {
        let columns = CGFloat(EstimatePayload.jarColumns)
        let naturalWidth = s(176)
        let naturalHeight = naturalWidth / columns * 8.4 + s(8) * 2 + s(16) - 3
        // The whole jar scales down together when the full-size jar would not fit the height offered.
        return GeometryReader { geo in
            jarPicture(fit: min(1, geo.size.height / naturalHeight))
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minHeight: naturalHeight * 0.55, idealHeight: naturalHeight, maxHeight: naturalHeight)
    }

    private func jarPicture(fit: CGFloat) -> some View {
        let columns = CGFloat(EstimatePayload.jarColumns)
        let pad = s(8) * fit
        let width = s(176) * fit
        let cell = width / columns
        let height = cell * 8.4 + pad * 2
        let tones = [GeniColor.pink, GeniColor.yellow, GeniColor.orange, GeniColor.green]
        return VStack(spacing: -3 * fit) {
            RoundedRectangle(cornerRadius: 4)
                .fill(GeniColor.orange)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(GameStyle.hairline, lineWidth: 1.5))
                .frame(width: width * 0.8, height: s(16) * fit)
                .zIndex(1)
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 28,
                                       bottomTrailingRadius: 28, topTrailingRadius: 6)
                    .fill(GeniColor.cyan.soft(0.3))
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 28,
                                                    bottomTrailingRadius: 28, topTrailingRadius: 6)
                        .stroke(GameStyle.hairline, lineWidth: 1.5))
                ForEach(Array(payload.beans.enumerated()), id: \.offset) { _, bean in
                    Circle()
                        .fill(tones[bean.tone % tones.count])
                        .overlay(Circle().stroke(GameStyle.hairline, lineWidth: 1))
                        .frame(width: cell * 0.78, height: cell * 0.78)
                        .position(x: pad + bean.x * cell, y: height - pad - bean.y * cell)
                }
            }
            .frame(width: width + pad * 2, height: height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("🫙")
    }
}
