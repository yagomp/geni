import SwiftUI

struct DataGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        VStack(spacing: expanded ? 36 : 24) {
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

    var body: some View {
        let height = scaled(34, expanded: expanded)
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
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Rectangle().fill(GeniColor.lightGray).frame(height: 2)
                }
                HStack(spacing: scaled(12, expanded: expanded)) {
                    Text(row.emoji)
                        .font(.system(size: scaled(36, expanded: expanded)))
                        .frame(width: scaled(48, expanded: expanded))
                    TallyMarks(count: row.count)
                    Spacer(minLength: 0)
                }
                .frame(height: scaled(56, expanded: expanded))
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
        let plotHeight = s(150)
        let labelled = Array(stride(from: 0, through: top, by: 2))
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

            VStack(spacing: s(6)) {
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

                HStack(spacing: s(12)) {
                    ForEach(Array(payload.bars.enumerated()), id: \.offset) { _, bar in
                        Text(bar.emoji)
                            .font(.system(size: s(34)))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, s(8))
            }
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
        let width = s(176)
        let cell = width / columns
        let pad = s(8)
        let height = cell * 8.4 + pad * 2
        let tones = [GeniColor.pink, GeniColor.yellow, GeniColor.orange, GeniColor.green]
        return VStack(spacing: -3) {
            RoundedRectangle(cornerRadius: 4)
                .fill(GeniColor.orange)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(GameStyle.hairline, lineWidth: 1.5))
                .frame(width: width * 0.8, height: s(16))
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
