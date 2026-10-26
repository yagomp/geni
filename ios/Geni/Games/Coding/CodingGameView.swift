import SwiftUI

struct CodingGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? CodingGridPayload {
            VStack(spacing: GameStyle.gap(24, expanded: expanded)) {
                GameQuestion(text: spec.prompt)
                GameSceneCard(framed: false) { RobotGrid(board: payload.board) }
                VStack(spacing: GameStyle.gap(8, expanded: expanded)) {
                    ForEach(Array(payload.choices.enumerated()), id: \.element.value) { i, choice in
                        GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM,
                                       persistence: persistence, height: 64) {
                            ProgramStrip(program: payload.programs[i])
                        }
                        .accessibilityLabel(CodingGames.spoken(payload.programs[i]))
                    }
                }
            }
        } else if let payload = spec.payload as? SymmetryPayload {
            VStack(spacing: GameStyle.gap(24, expanded: expanded)) {
                GameQuestion(text: spec.prompt)
                GameSceneCard(framed: false) { MirrorPicture(left: payload.left) }
                HStack(spacing: GameStyle.gap(14, expanded: expanded)) {
                    ForEach(Array(payload.choices.enumerated()), id: \.element.value) { i, choice in
                        GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM,
                                       persistence: persistence, height: payload.left.count > 4 ? 128 : 112) {
                            PaintGrid(cells: payload.halves[i], cell: pictureSize(18, expanded: expanded))
                        }
                    }
                }
            }
        } else if let payload = spec.payload as? ChoicePayload {
            ChoiceGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        }
    }
}

/// Picture sizes: phone base, ×1.35 on compact iPad, ×1.6 on the expanded iPad layout.
private func pictureSize(_ base: CGFloat, expanded: Bool) -> CGFloat {
    expanded ? base * 1.6 : iPadScale.value(base)
}

// MARK: - Robot grid

/// Soft rounded squares; the robot's square is blue-tinted, the star's yellow. Rocks block the way.
private struct RobotGrid: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let board: CodingBoard

    var body: some View {
        let cell = pictureSize(board.size >= 5 ? 32 : 40, expanded: expanded)
        let gap = cell * 0.1
        VStack(spacing: gap) {
            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<board.size, id: \.self) { column in
                        let here = CodingCell(column, row)
                        ZStack {
                            GeniShape(radius: GameStyle.cellRadius(cell, 0.28)).fill(fill(here))
                            Text(emoji(here)).font(.system(size: cell * 0.68))
                        }
                        .frame(width: cell, height: cell)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("🤖 ⭐")
    }

    private func emoji(_ cell: CodingCell) -> String {
        if cell == board.robot { return "🤖" }
        if cell == board.star { return "⭐" }
        return board.rocks.contains(cell) ? "🪨" : ""
    }

    private func fill(_ cell: CodingCell) -> Color {
        if cell == board.robot { return GeniColor.cyan.soft(0.35) }
        if cell == board.star { return GeniColor.yellow.soft(0.4) }
        return GeniColor.lightGray.soft(0.7)
    }
}

/// Big arrows in a row; a loop is a soft orange bracket around its arrows with "×3" beside it.
private struct ProgramStrip: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let program: CodingProgram

    var body: some View {
        let arrow = pictureSize(program.flattenedWidth > 6 ? 24 : 28, expanded: expanded)
        let loopFill = GeniColor.orange.soft(0.18)
        HStack(spacing: arrow * 0.45) {
            ForEach(Array(program.enumerated()), id: \.offset) { _, step in
                if step.times == 1 {
                    arrows(step.moves, size: arrow)
                } else {
                    HStack(spacing: arrow * 0.2) {
                        arrows(step.moves, size: arrow)
                            .padding(.horizontal, arrow * 0.3)
                            .padding(.vertical, arrow * 0.18)
                            .foregroundStyle(loopFill.readableText)
                            .background(GeniShape(radius: GameStyle.cellRadius(arrow, 0.45)).fill(loopFill))
                            .overlay(GeniShape(radius: GameStyle.cellRadius(arrow, 0.45)).stroke(GeniColor.orange, lineWidth: 3))
                        Text("×\(step.times)")
                            .font(.system(size: arrow * 1.05, weight: .black, design: .rounded))
                            .fixedSize()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
    }

    private func arrows(_ moves: [CodingMove], size: CGFloat) -> some View {
        HStack(spacing: size * 0.2) {
            ForEach(Array(moves.enumerated()), id: \.offset) { _, move in
                Image(systemName: move.symbol)
                    .font(.system(size: size * 0.9, weight: .bold))
                    .frame(width: size, height: size)
            }
        }
    }
}

private extension Array where Element == CodingStep {
    /// Arrows drawn on screen (a loop's arrows once), to shrink long programs a little.
    var flattenedWidth: Int { reduce(0) { $0 + $1.moves.count } }
}

// MARK: - Symmetry

/// Painted squares of one half picture. 0 is an empty, pale square.
private struct PaintGrid: View {
    let cells: [[Int]]
    let cell: CGFloat

    var body: some View {
        let gap = cell * 0.14
        VStack(spacing: gap) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, paint in
                        GeniShape(radius: GameStyle.cellRadius(cell, 0.26))
                            .fill(paint == 0 ? GeniColor.lightGray.soft(0.7) : Self.color(paint))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
    }

    static func color(_ paint: Int) -> Color {
        [GeniColor.blue, GeniColor.pink, GeniColor.green, GeniColor.orange, GeniColor.cyan][(paint - 1) % CodingGames.paintCount]
    }
}

/// The left half painted, a dashed mirror line, and the empty right half waiting to be finished.
private struct MirrorPicture: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let left: [[Int]]

    var body: some View {
        let cell = pictureSize(left.count > 4 ? 26 : 30, expanded: expanded)
        let gap = cell * 0.14
        let empty = left.map { $0.map { _ in 0 } }
        HStack(spacing: cell * 0.35) {
            PaintGrid(cells: left, cell: cell)
            MirrorLine()
                .stroke(GeniColor.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 7]))
                .frame(width: 3, height: CGFloat(left.count) * (cell + gap) + cell * 0.4)
            PaintGrid(cells: empty, cell: cell)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("🪞")
    }
}

private struct MirrorLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}
