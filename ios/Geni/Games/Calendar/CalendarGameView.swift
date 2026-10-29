import SwiftUI

struct CalendarGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    /// The week's "?" gap, where a day tile can be dropped.
    @State private var slot: CGRect = .zero
    @State private var slotHovered = false

    var body: some View {
        if let payload = spec.payload as? CalendarPayload {
            VStack(spacing: expanded ? 36 : 20) {
                GameQuestion(text: spec.prompt)
                GameSceneCard { scene(payload.scene) }
                choices(payload)
            }
        }
    }

    /// The gap shows the right day once it's answered (or shown after the second miss).
    private var solved: Bool {
        chapterVM.showFeedback && (chapterVM.feedbackCorrect || chapterVM.showAnswer)
    }

    @ViewBuilder
    private func scene(_ scene: CalendarPayload.Scene) -> some View {
        switch scene {
        case .week(let cells):
            WeekRow(cells: cells, solved: solved, hovered: slotHovered) { slot = $0 }
        case .month(let name):
            MonthPage(name: name)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: expanded ? 120 : iPadScale.value(84)))
                .minimumScaleFactor(0.5)
        case .solid(let solid):
            SolidFigure(solid: solid, size: expanded ? 220 : iPadScale.value(130))
        }
    }

    @ViewBuilder
    private func choices(_ payload: CalendarPayload) -> some View {
        switch payload.style {
        case .text where isWeek(payload):
            DayChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence,
                       target: GameDropTarget(frame: slot) { slotHovered = $0 })
        case .text:
            GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        case .emoji:
            HStack(spacing: 12) {
                ForEach(payload.choices, id: \.value) { choice in
                    GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM, persistence: persistence) {
                        Text(choice.label)
                            .font(.system(size: expanded ? 64 : iPadScale.value(44)))
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        case .solids:
            HStack(spacing: 12) {
                ForEach(payload.choices, id: \.value) { choice in
                    GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM,
                                   persistence: persistence, height: 112) {
                        SolidFigure(solid: Solid(rawValue: choice.value) ?? .cube, size: expanded ? 130 : iPadScale.value(80))
                    }
                    .accessibilityLabel(choice.label)
                }
            }
        }
    }

    private func isWeek(_ payload: CalendarPayload) -> Bool {
        if case .week = payload.scene { return true }
        return false
    }
}

/// The whole week in order, every day named in full, with one "?" gap to fill.
/// One row when the names fit, else 4 + 3, else a column (long names on a phone).
private struct WeekRow: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let cells: [WeekCell]
    let solved: Bool
    let hovered: Bool
    let onSlot: (CGRect) -> Void

    var body: some View {
        let widest = cells.max { $0.label.count < $1.label.count }?.label ?? ""
        let big: CGFloat = expanded ? 26 : iPadScale.value(18)
        ViewThatFits(in: .horizontal) {
            row(widest: widest, size: big)
            row(widest: widest, size: expanded ? 21 : iPadScale.value(15))
            Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                GridRow { cards(0..<4, widest: widest, size: big) }
                GridRow { cards(4..<7, widest: widest, size: big) }
            }
            VStack(spacing: 4) { cards(0..<7, widest: widest, size: iPadScale.value(18), height: iPadScale.value(32)) }
                .frame(maxWidth: 320)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cells.map { $0.state == .missing && !solved ? missingDay : $0.label }.joined(separator: ", "))
    }

    private var gap: CGFloat { expanded ? 10 : 6 }
    private var missingDay: String {
        L.t("missing day", no: "dagen som mangler", es: "el día que falta", pt: "o dia que falta")
    }

    private func row(widest: String, size: CGFloat) -> some View {
        HStack(spacing: gap) { cards(0..<7, widest: widest, size: size) }
    }

    private func cards(_ range: Range<Int>, widest: String, size: CGFloat, height: CGFloat? = nil) -> some View {
        ForEach(range, id: \.self) { i in
            WeekdayCard(cell: cells[i], widest: widest, size: size,
                        height: height ?? (expanded ? 96 : iPadScale.value(64)),
                        solved: solved, hovered: hovered, onSlot: onSlot)
        }
    }
}

/// One day of the week, or the "?" gap where a tile can be dropped (filled in once solved).
private struct WeekdayCard: View {
    let cell: WeekCell
    /// The longest name in the week, so every card in a row is equally wide.
    let widest: String
    let size: CGFloat
    let height: CGFloat
    let solved: Bool
    let hovered: Bool
    let onSlot: (CGRect) -> Void

    private var isGap: Bool { cell.state == .missing }
    private var shape: GeniShape { GeniShape(scale: 0.4) }

    var body: some View {
        ZStack {
            Text(widest).hidden()
            Text(isGap && !solved ? "?" : cell.label)
        }
        .font(.system(size: isGap && !solved ? size * 1.4 : size, weight: .black, design: .rounded))
        .foregroundStyle(isGap && solved ? Color.white : GeniColor.border)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(background, in: shape)
        .overlay {
            if isGap && !solved {
                shape.stroke(GeniColor.border.opacity(hovered ? 0.6 : 0.3),
                             style: StrokeStyle(lineWidth: hovered ? 3.5 : 2.5, dash: [7, 5]))
            } else {
                shape.stroke(GameStyle.hairline, lineWidth: 1.5)
            }
        }
        .scaleEffect(isGap && hovered ? 1.08 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hovered)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: solved)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            if isGap { onSlot(frame) }
        }
    }

    private var background: Color {
        switch cell.state {
        case .shown: return GeniColor.card
        case .anchor: return GeniColor.cyan
        case .missing: return solved ? GeniColor.green : GeniColor.yellow
        }
    }
}

/// The day tiles under the week: tap one, or drag it into the "?" gap. All in one row when the names fit.
private struct DayChoices: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let choices: [GameChoice]
    let exercise: Exercise
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    let target: GameDropTarget

    var body: some View {
        let widest = choices.max { $0.label.count < $1.label.count }?.label ?? ""
        let gap = GameStyle.gap(14, expanded: expanded)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: gap) { tiles(choices, widest: widest) }
            VStack(spacing: gap) {
                ForEach(Array(stride(from: 0, to: choices.count, by: 2)), id: \.self) { start in
                    HStack(spacing: gap) {
                        tiles(Array(choices[start..<min(start + 2, choices.count)]), widest: widest)
                        if start + 1 == choices.count { Color.clear.frame(maxWidth: .infinity, maxHeight: 1) }
                    }
                }
            }
        }
    }

    private func tiles(_ items: [GameChoice], widest: String) -> some View {
        ForEach(items, id: \.value) { choice in
            GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM, persistence: persistence,
                           height: expanded ? 72 : 64, dropTarget: target) {
                ZStack {
                    Text(widest).hidden()
                    Text(choice.label)
                }
                .font(.system(size: expanded ? 36 : iPadScale.value(24), weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 10)
            }
        }
    }
}

/// A page torn from a wall calendar with the month's name.
private struct MonthPage: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let name: String

    var body: some View {
        VStack(spacing: 0) {
            GeniColor.pink
                .frame(height: expanded ? 36 : iPadScale.value(24))
            Text(name)
                .font(.system(size: expanded ? 64 : iPadScale.value(40), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: expanded ? 110 : iPadScale.value(72))
                .background(GeniColor.card)
        }
        .clipShape(GeniShape(scale: 0.5))
        .overlay(GeniShape(scale: 0.5).stroke(GameStyle.hairline, lineWidth: 1.5))
        .frame(maxWidth: expanded ? 460 : 280)
    }
}
