import SwiftUI

/// Two columns of cards; kids connect pairs by dragging a line from either side
/// or by tapping one card and then its partner.
struct MatchConnectBoard: View {
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    let leftLabels: [String]
    let rightLabels: [String]
    var leftClocks: [ClockTime]? = nil

    @Environment(\.geniExpandedLayout) private var expanded
    @State private var drag: Drag?
    @State private var selection: Endpoint?

    private enum Side { case left, right }

    private struct Endpoint: Equatable {
        let side: Side
        let index: Int
    }

    private struct Drag {
        let origin: Endpoint
        var location: CGPoint
        var target: Endpoint?
    }

    private var pairCount: Int { min(leftLabels.count, rightLabels.count) }
    private var itemHeight: CGFloat { expanded ? (leftClocks == nil ? 112 : 156) : iPadScale.value(leftClocks == nil ? 52 : 104) }
    private var itemSpacing: CGFloat { expanded ? 24 : 12 }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                HStack(spacing: 0) {
                    column(.left, labels: leftLabels)
                        .frame(width: size.width * 0.38)
                    Spacer(minLength: 0)
                    column(.right, labels: rightLabels)
                        .frame(width: size.width * 0.38)
                }

                Canvas { context, _ in
                    drawLines(in: &context, size: size)
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(size: size))
        }
        .frame(height: CGFloat(pairCount) * (itemHeight + itemSpacing) - itemSpacing + 20)
        .onChange(of: chapterVM.currentIndex) { _, _ in
            drag = nil
            selection = nil
        }
    }

    // MARK: - Cards

    private func column(_ side: Side, labels: [String]) -> some View {
        VStack(spacing: itemSpacing) {
            ForEach(0..<pairCount, id: \.self) { i in
                let endpoint = Endpoint(side: side, index: i)
                let matched = isMatched(endpoint)
                let active = drag?.origin == endpoint || drag?.target == endpoint || selection == endpoint
                let wrong = isWrong(endpoint)
                let color = matched ? GeniColor.green : (wrong ? GeniColor.pinkDeep : (active ? GeniColor.blue : GeniColor.border))
                let textColor = matched ? GeniColor.border : color
                let fill = matched ? GeniColor.green.soft(0.15) : (wrong ? GeniColor.pink.soft(0.25) : (active ? GeniColor.blue.soft(0.15) : GeniColor.card))

                Group {
                    if side == .left, let clocks = leftClocks, clocks.indices.contains(i) {
                        ClockFaceView(time: clocks[i]).padding(5)
                    } else {
                        Text(labels[i])
                    }
                }
                    .font(.system(size: expanded ? 40 : iPadScale.value(side == .left ? 20 : 22), weight: .black, design: .rounded))
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity)
                    .frame(height: itemHeight)
                    .background(fill)
                    .clipShape(GeniShape())
                    .overlay(GeniShape().stroke(color, lineWidth: 3))
                    .background(GeniShape().fill(GeniColor.border).offset(x: 3, y: 3))
                    .scaleEffect(active && !matched ? 1.04 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: active)
                    .animation(.easeOut(duration: 0.2), value: wrong)
                    .accessibilityIdentifier("match.\(side == .left ? "left" : "right").\(i)")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Geometry

    private func itemY(_ index: Int, height: CGFloat) -> CGFloat {
        let total = CGFloat(pairCount) * itemHeight + CGFloat(pairCount - 1) * itemSpacing
        return (height - total) / 2 + CGFloat(index) * (itemHeight + itemSpacing) + itemHeight / 2
    }

    /// Point on the inner edge of a card, where its line attaches.
    private func anchor(_ endpoint: Endpoint, size: CGSize) -> CGPoint {
        let x = endpoint.side == .left ? size.width * 0.38 : size.width * 0.62
        return CGPoint(x: x, y: itemY(endpoint.index, height: size.height))
    }

    private func nearestIndex(toY y: CGFloat, height: CGFloat) -> Int? {
        let pitch = itemHeight + itemSpacing
        let candidates = (0..<pairCount).map { ($0, abs(itemY($0, height: height) - y)) }
        guard let best = candidates.min(by: { $0.1 < $1.1 }), best.1 <= pitch * 0.75 else { return nil }
        return best.0
    }

    /// The card a touch lands on. Cards are generous targets: anywhere on the
    /// card's half of the board counts.
    private func endpoint(at point: CGPoint, size: CGSize) -> Endpoint? {
        let side: Side
        if point.x <= size.width * 0.45 {
            side = .left
        } else if point.x >= size.width * 0.55 {
            side = .right
        } else {
            return nil
        }
        return nearestIndex(toY: point.y, height: size.height).map { Endpoint(side: side, index: $0) }
    }

    /// Where a line being dragged from `origin` would land. Once the finger is past
    /// the middle, the nearest free card on the other side catches it.
    private func dropTarget(for origin: Endpoint, at point: CGPoint, size: CGSize) -> Endpoint? {
        let crossed = origin.side == .left ? point.x >= size.width * 0.5 : point.x <= size.width * 0.5
        guard crossed, let index = nearestIndex(toY: point.y, height: size.height) else { return nil }
        let target = Endpoint(side: origin.side == .left ? .right : .left, index: index)
        return isMatched(target) ? nil : target
    }

    private func isWrong(_ endpoint: Endpoint) -> Bool {
        guard let wrong = chapterVM.wrongMatchStroke else { return false }
        return endpoint.side == .left ? wrong.leftIndex == endpoint.index : wrong.rightIndex == endpoint.index
    }

    private func isMatched(_ endpoint: Endpoint) -> Bool {
        chapterVM.completedMatches.contains {
            endpoint.side == .left ? $0.leftIndex == endpoint.index : $0.rightIndex == endpoint.index
        }
    }

    // MARK: - Interaction

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !chapterVM.isAwaitingAdvance else { return }

                if drag == nil {
                    guard let origin = endpoint(at: value.startLocation, size: size), !isMatched(origin) else { return }
                    drag = Drag(origin: origin, location: value.startLocation)
                    HapticManager.selection()
                }
                guard var current = drag else { return }

                current.location = value.location
                let target = dropTarget(for: current.origin, at: value.location, size: size)
                if target != current.target, target != nil {
                    HapticManager.selection()
                }
                current.target = target
                drag = current
            }
            .onEnded { value in
                defer { drag = nil }
                guard !chapterVM.isAwaitingAdvance else { return }

                let moved = hypot(value.translation.width, value.translation.height)
                if moved < 12 {
                    tap(endpoint(at: value.startLocation, size: size))
                    return
                }

                guard let current = drag,
                      let target = dropTarget(for: current.origin, at: value.location, size: size)
                else { return }
                selection = nil
                connect(current.origin, target)
            }
    }

    private func tap(_ endpoint: Endpoint?) {
        guard let endpoint, !isMatched(endpoint) else {
            selection = nil
            return
        }

        if let selected = selection, selected.side != endpoint.side {
            selection = nil
            connect(selected, endpoint)
        } else {
            selection = selection == endpoint ? nil : endpoint
        }
    }

    private func connect(_ a: Endpoint, _ b: Endpoint) {
        let left = a.side == .left ? a : b
        let right = a.side == .left ? b : a
        chapterVM.submitMatch(leftIndex: left.index, rightIndex: right.index, persistence: persistence)
    }

    // MARK: - Drawing

    private var lineStyle: StrokeStyle {
        StrokeStyle(lineWidth: expanded ? 10 : iPadScale.value(6), lineCap: .round, lineJoin: .round)
    }

    /// A soft cable between two points: leaves each card horizontally and sags a
    /// little with length, so it bends with the finger instead of zig-zagging.
    private func cable(from start: CGPoint, to end: CGPoint, leavesRight: Bool) -> Path {
        let dx = end.x - start.x
        let length = hypot(dx, end.y - start.y)
        let reach = max(abs(dx) * 0.5, 28)
        let sag = min(length * 0.12, 26)
        let direction: CGFloat = leavesRight ? 1 : -1

        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x + reach * direction, y: start.y + sag),
            control2: CGPoint(x: end.x - reach * direction, y: end.y + sag)
        )
        return path
    }

    private func connection(_ left: Int, _ right: Int, size: CGSize) -> Path {
        cable(
            from: anchor(Endpoint(side: .left, index: left), size: size),
            to: anchor(Endpoint(side: .right, index: right), size: size),
            leavesRight: true
        )
    }

    private func drawLines(in context: inout GraphicsContext, size: CGSize) {
        for stroke in chapterVM.completedMatches {
            context.stroke(connection(stroke.leftIndex, stroke.rightIndex, size: size), with: .color(GeniColor.green), style: lineStyle)
        }

        if let wrong = chapterVM.wrongMatchStroke {
            context.stroke(connection(wrong.leftIndex, wrong.rightIndex, size: size), with: .color(GeniColor.pink), style: lineStyle)
        }

        if let drag {
            let start = anchor(drag.origin, size: size)
            let end = drag.target.map { anchor($0, size: size) } ?? drag.location
            context.stroke(
                cable(from: start, to: end, leavesRight: drag.origin.side == .left),
                with: .color(GeniColor.blue),
                style: lineStyle
            )
        }

        // Attachment dots show where lines start and end.
        let dotSize = expanded ? 22 : iPadScale.value(14)
        for side in [Side.left, .right] {
            for i in 0..<pairCount {
                let endpoint = Endpoint(side: side, index: i)
                let point = anchor(endpoint, size: size)
                let color: Color = isMatched(endpoint)
                    ? GeniColor.green
                    : (isWrong(endpoint) ? GeniColor.pink
                        : (drag?.origin == endpoint || drag?.target == endpoint || selection == endpoint ? GeniColor.blue : GeniColor.yellow))
                let rect = CGRect(x: point.x - dotSize / 2, y: point.y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.stroke(Path(ellipseIn: rect), with: .color(GeniColor.border), lineWidth: 2)
            }
        }
    }
}
