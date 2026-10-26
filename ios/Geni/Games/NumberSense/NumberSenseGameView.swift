import SwiftUI

struct NumberSenseGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? ChoicePayload {
            ChoiceGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        } else if let payload = spec.payload as? TenFramePayload {
            screen(choices: payload.choices, framed: !payload.showsFrame) {
                VStack(spacing: expanded ? 24 : 16) {
                    if payload.showsFrame {
                        TenFramePicture(filled: payload.filled, emoji: payload.emoji, isAnswering: chapterVM.showFeedback)
                            .id(exercise.id)
                    }
                    if !payload.equation.isEmpty { SumRow(tokens: payload.equation) }
                }
            }
        } else if let payload = spec.payload as? DoublesPayload {
            screen(choices: payload.choices) {
                VStack(spacing: expanded ? 24 : 16) {
                    DoublesPictureView(payload: payload)
                    if !payload.equation.isEmpty { SumRow(tokens: payload.equation) }
                }
            }
        } else if let payload = spec.payload as? NumberTrackPayload {
            screen(choices: payload.choices) {
                switch payload.style {
                case .houses: HouseStreet(numbers: payload.numbers)
                case .countdown: RocketCountdown(numbers: payload.numbers)
                }
            }
        } else if let payload = spec.payload as? FrogHopPayload {
            screen(choices: payload.choices) {
                FrogHops(numbers: payload.numbers, step: payload.step)
            }
        }
    }

    private func screen<Picture: View>(choices: [GameChoice], framed: Bool = true,
                                       @ViewBuilder picture: () -> Picture) -> some View {
        VStack(spacing: expanded ? 36 : 24) {
            GameQuestion(text: spec.prompt)
            GameSceneCard(framed: framed) { picture() }
            GameChoices(choices: choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }
}

/// Picture sizes: phone base, ×1.35 on compact iPad, ×1.6 on the expanded iPad layout.
private func pictureSize(_ base: CGFloat, expanded: Bool) -> CGFloat {
    expanded ? base * 1.6 : iPadScale.value(base)
}

// MARK: - Ten-frame

/// Two rows of five; filled cells carry the picture, empty ones are pale and dashed so the gap is obvious.
private struct TenFramePicture: View {
    @Environment(\.geniExpandedLayout) private var expanded
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedPieces = 0
    let filled: Int
    let emoji: String
    let isAnswering: Bool

    var body: some View {
        let cell = pictureSize(54, expanded: expanded)
        VStack(spacing: 0) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { col in
                        let isFilled = row * 5 + col < filled
                        ZStack {
                            Rectangle().fill(isFilled ? GeniColor.card : GeniColor.lightGray.soft(0.5))
                            if isFilled {
                                Text(emoji).font(.system(size: cell * 0.6))
                                    .opacity(reduceMotion || isAnswering || row * 5 + col < revealedPieces ? 1 : 0)
                            } else {
                                GeniShape(radius: GameStyle.cellRadius(cell, 0.2))
                                    .stroke(GeniColor.border.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                    .padding(cell * 0.16)
                            }
                        }
                        .frame(width: cell, height: cell)
                        .overlay(Rectangle().stroke(GameStyle.hairline, lineWidth: 1))
                    }
                }
            }
        }
        .clipShape(GeniShape(scale: 0.5))
        .overlay(GeniShape(scale: 0.5).stroke(GameStyle.hairline, lineWidth: 1.5))
        .shadow(color: GameStyle.shadow, radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) / 10")
        .task(id: isAnswering) {
            let pieces = min(max(filled, 0), 10)
            guard !reduceMotion, !isAnswering else {
                revealedPieces = pieces
                return
            }
            for count in min(revealedPieces, pieces)..<pieces {
                do { try await Task.sleep(for: .seconds(0.08)) } catch { return }
                guard !Task.isCancelled else { return }
                revealedPieces = count + 1
                HapticManager.countTick()
            }
        }
    }
}

// MARK: - Sum row

/// "7 + ? = 10" as big tiles; the gap is a yellow tile.
private struct SumRow: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let tokens: [String]

    var body: some View {
        let tile = pictureSize(52, expanded: expanded)
        HStack(spacing: expanded ? 12 : 6) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                let isNumber = token.first.map { $0.isNumber || $0 == "?" } ?? false
                Text(token)
                    .font(.system(size: tile * (isNumber ? 0.58 : 0.66), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: isNumber ? tile : tile * 0.5, height: tile)
                    .background {
                        if isNumber {
                            GeniShape(scale: 0.5).fill(token == "?" ? GeniColor.yellow : GeniColor.card)
                                .overlay(GeniShape(scale: 0.5).stroke(GameStyle.hairline, lineWidth: 1.5))
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tokens.joined(separator: " "))
    }
}

// MARK: - Dots

/// Dot positions in a unit square: dice faces up to 6, then two neat columns.
private enum DotLayout {
    static func points(_ n: Int) -> [CGPoint] {
        let a: CGFloat = 0.25, c: CGFloat = 0.5, b: CGFloat = 0.75
        switch n {
        case 1: return [CGPoint(x: c, y: c)]
        case 2: return [CGPoint(x: a, y: a), CGPoint(x: b, y: b)]
        case 3: return [CGPoint(x: a, y: a), CGPoint(x: c, y: c), CGPoint(x: b, y: b)]
        case 4: return [CGPoint(x: a, y: a), CGPoint(x: b, y: a), CGPoint(x: a, y: b), CGPoint(x: b, y: b)]
        case 5: return points(4) + [CGPoint(x: c, y: c)]
        case 6: return column(x: a, rows: 3) + column(x: b, rows: 3)
        case 7: return points(6) + [CGPoint(x: c, y: c)]
        case 9: return column(x: 0.22, rows: 3) + column(x: c, rows: 3) + column(x: 0.78, rows: 3)
        default:
            let rows = Int((Double(n) / 2).rounded(.up))
            return Array((column(x: a, rows: rows) + column(x: b, rows: rows)).prefix(n))
        }
    }

    private static func column(x: CGFloat, rows: Int) -> [CGPoint] {
        (0..<rows).map { CGPoint(x: x, y: (CGFloat($0) + 0.5) / CGFloat(rows)) }
    }
}

/// `count` black dots laid out in a box, optionally mirrored left–right.
private struct Dots: View {
    let count: Int
    var mirrored = false
    let dot: CGFloat

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(DotLayout.points(count).enumerated()), id: \.offset) { _, p in
                Circle()
                    .fill(GeniColor.border)
                    .frame(width: dot, height: dot)
                    .position(x: (mirrored ? 1 - p.x : p.x) * geo.size.width, y: p.y * geo.size.height)
            }
        }
    }
}

// MARK: - Doubles

/// Two dice, one domino or a ladybird: the two halves mirror each other.
private struct DoublesPictureView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let payload: DoublesPayload

    var body: some View {
        Group {
            switch payload.picture {
            case .dice: dice
            case .domino: domino
            case .ladybird: ladybird
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(payload.left) + \(payload.right)")
    }

    private var dice: some View {
        let side = pictureSize(110, expanded: expanded)
        return HStack(spacing: side * 0.25) {
            die(payload.left, mirrored: true, side: side)
            die(payload.right, mirrored: false, side: side)
        }
    }

    private func die(_ n: Int, mirrored: Bool, side: CGFloat) -> some View {
        Dots(count: n, mirrored: mirrored, dot: side * 0.18)
            .padding(side * 0.08)
            .frame(width: side, height: side)
            .background(GeniColor.card, in: RoundedRectangle(cornerRadius: side * 0.2))
            .overlay(RoundedRectangle(cornerRadius: side * 0.2).stroke(GameStyle.hairline, lineWidth: 1.5))
            .shadow(color: GameStyle.shadow, radius: 6, x: 0, y: 3)
    }

    private var domino: some View {
        let half = pictureSize(108, expanded: expanded)
        return HStack(spacing: 0) {
            Dots(count: payload.left, mirrored: true, dot: half * 0.17)
                .padding(half * 0.1)
                .frame(width: half, height: half)
            Rectangle().fill(GameStyle.hairline).frame(width: 2, height: half * 0.8)
            Dots(count: payload.right, dot: half * 0.17)
                .padding(half * 0.1)
                .frame(width: half, height: half)
        }
        .background(GeniColor.card, in: RoundedRectangle(cornerRadius: half * 0.18))
        .overlay(RoundedRectangle(cornerRadius: half * 0.18).stroke(GameStyle.hairline, lineWidth: 1.5))
        .shadow(color: GameStyle.shadow, radius: 6, x: 0, y: 3)
    }

    private var wingColor: Color {
        [GeniColor.pink, GeniColor.orange, GeniColor.yellow][payload.tint % 3]
    }

    /// Two wings split down the middle under a round black head; spots mirror across the split.
    private var ladybird: some View {
        let wingWidth = pictureSize(104, expanded: expanded)
        let wingHeight = pictureSize(140, expanded: expanded)
        let head = wingWidth * 0.5
        let dot = wingWidth * (max(payload.left, payload.right) > 6 ? 0.14 : 0.2)
        return ZStack(alignment: .top) {
            HStack(spacing: 0) {
                wing(payload.left, mirrored: true, dot: dot, headOverlap: head * 0.25)
                wing(payload.right, mirrored: false, dot: dot, headOverlap: head * 0.25)
            }
            .frame(width: wingWidth * 2, height: wingHeight)
            .padding(.top, head * 0.75)
            Circle()
                .fill(GeniColor.border)
                .frame(width: head, height: head)
        }
    }

    private func wing(_ n: Int, mirrored: Bool, dot: CGFloat, headOverlap: CGFloat) -> some View {
        ZStack {
            HalfOval(rightSide: !mirrored).fill(wingColor)
            HalfOval(rightSide: !mirrored).stroke(GameStyle.hairline, lineWidth: 1.5)
            // Keep spots inside the curve: the outer edge narrows, so pull them toward the split.
            Dots(count: n, mirrored: mirrored, dot: dot)
                .padding(.top, dot + headOverlap)
                .padding(.bottom, dot)
                .padding(mirrored ? .trailing : .leading, dot * 0.3)
                .padding(mirrored ? .leading : .trailing, dot * 1.1)
        }
    }
}

/// One half of an oval, flat side at the split.
private struct HalfOval: Shape {
    let rightSide: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let flatX = rightSide ? rect.minX : rect.maxX
        let outerX = rightSide ? rect.maxX : rect.minX
        path.move(to: CGPoint(x: flatX, y: rect.minY))
        path.addCurve(to: CGPoint(x: flatX, y: rect.maxY),
                      control1: CGPoint(x: outerX + (outerX - flatX) * 0.25, y: rect.minY - rect.height * 0.02),
                      control2: CGPoint(x: outerX + (outerX - flatX) * 0.25, y: rect.maxY + rect.height * 0.1))
        path.closeSubpath()
        return path
    }
}

// MARK: - Number neighbours

/// A street of numbered houses; the gap is an empty white house with a "?".
private struct HouseStreet: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let numbers: [Int?]

    private let walls = [GeniColor.yellow, GeniColor.cyan, GeniColor.orange, GeniColor.green, GeniColor.pink]

    var body: some View {
        let width = pictureSize(numbers.count > 4 ? 50 : 62, expanded: expanded)
        HStack(alignment: .bottom, spacing: expanded ? 12 : 6) {
            ForEach(Array(numbers.enumerated()), id: \.offset) { _, number in
                let wall = number == nil ? GeniColor.card : walls[(number ?? 0) % walls.count].soft(0.55)
                VStack(spacing: 0) {
                    Roof()
                        .fill(number == nil ? GeniColor.card : GeniColor.pink.soft(0.8))
                        .overlay(Roof().stroke(GameStyle.hairline, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)))
                        .frame(width: width * 1.08, height: width * 0.55)
                    Text(number.map(String.init) ?? "?")
                        .font(.system(size: width * 0.5, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: width, height: width * 0.95)
                        .background(wall)
                        .overlay(Rectangle().stroke(GameStyle.hairline, lineWidth: 1.5))
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(numbers.map { $0.map(String.init) ?? "?" }.joined(separator: ", "))
    }
}

private struct Roof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Count backwards

/// Countdown bubbles that shrink toward a rocket on its launch pad.
private struct RocketCountdown: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let numbers: [Int?]

    var body: some View {
        let bubble = pictureSize(52, expanded: expanded)
        HStack(alignment: .bottom, spacing: expanded ? 12 : 6) {
            ForEach(Array(numbers.enumerated()), id: \.offset) { _, number in
                Text(number.map(String.init) ?? "?")
                    .font(.system(size: bubble * 0.46, weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: bubble, height: bubble)
                    .background(number == nil ? GeniColor.card : GeniColor.orange.soft(0.6), in: Circle())
                    .overlay(Circle().stroke(GameStyle.hairline, lineWidth: 1.5))
                    .shadow(color: GameStyle.shadow, radius: 5, x: 0, y: 2)
                    .padding(.bottom, bubble * 0.2)
            }
            VStack(spacing: 0) {
                Text("🚀")
                    .font(.system(size: bubble))
                    .rotationEffect(.degrees(-45))
                Capsule()
                    .fill(GeniColor.border)
                    .frame(width: bubble * 1.2, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(numbers.map { $0.map(String.init) ?? "?" }.joined(separator: ", "))
    }
}

// MARK: - Skip counting

/// A number line with evenly spaced stops; arcs labelled "+2" show each hop and the frog waits on the last one.
private struct FrogHops: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let numbers: [Int?]
    let step: Int

    var body: some View {
        let height = pictureSize(150, expanded: expanded)
        let label = step > 0 ? "+\(step)" : "−\(-step)"
        let frogStop = numbers.lastIndex { $0 != nil } ?? 0
        GeometryReader { geo in
            let gap = geo.size.width / CGFloat(numbers.count)
            let x = { (i: Int) in gap * (CGFloat(i) + 0.5) }
            let lineY = height * 0.62
            let font = height * 0.15
            let arcTop = height * 0.05
            let labelY = (lineY - 10 + arcTop) / 2 - font * 0.75

            // The line itself, with a tick at every stop.
            Path { path in
                path.move(to: CGPoint(x: 0, y: lineY))
                path.addLine(to: CGPoint(x: geo.size.width, y: lineY))
                for i in numbers.indices {
                    path.move(to: CGPoint(x: x(i), y: lineY - 8))
                    path.addLine(to: CGPoint(x: x(i), y: lineY + 8))
                }
            }
            .stroke(GeniColor.border, style: StrokeStyle(lineWidth: 2, lineCap: .round))

            // Hops between neighbouring stops; the one into the gap is dashed.
            ForEach(0..<(numbers.count - 1), id: \.self) { i in
                let toGap = numbers[i + 1] == nil || numbers[i] == nil
                HopArc(from: x(i), to: x(i + 1), baseY: lineY - 10, controlY: arcTop)
                    .stroke(toGap ? GeniColor.orange : GeniColor.green,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: toGap ? [6, 5] : []))
                Text(label)
                    .font(.system(size: font * 0.85, weight: .heavy, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .position(x: (x(i) + x(i + 1)) / 2, y: labelY)
            }

            Text("🐸")
                .font(.system(size: font * 1.5))
                .position(x: x(frogStop), y: lineY - font * 1.1)

            ForEach(Array(numbers.enumerated()), id: \.offset) { i, number in
                Text(number.map(String.init) ?? "?")
                    .font(.system(size: font, weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: gap - 6, height: font * 1.6)
                    .background {
                        if number == nil {
                            GeniShape(scale: 0.4).fill(GeniColor.yellow)
                                .overlay(GeniShape(scale: 0.4).stroke(GameStyle.hairline, lineWidth: 1.5))
                        }
                    }
                    .position(x: x(i), y: lineY + font * 1.35)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(numbers.map { $0.map(String.init) ?? "?" }.joined(separator: ", "))
    }
}

private struct HopArc: Shape {
    let from: CGFloat
    let to: CGFloat
    let baseY: CGFloat
    let controlY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: from + 4, y: baseY))
        path.addQuadCurve(to: CGPoint(x: to - 4, y: baseY), control: CGPoint(x: (from + to) / 2, y: controlY))
        return path
    }
}
