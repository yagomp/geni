import SwiftUI

/// A closed polygon in a 0…1 square.
private struct UnitPolygon: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: map(first, in: rect))
        for point in points.dropFirst() { path.addLine(to: map(point, in: rect)) }
        path.closeSubpath()
        return path
    }

    private func map(_ p: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
    }
}

/// A straight line in a 0…1 square (for the edges hidden behind a solid).
private struct UnitLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + from.x * rect.width, y: rect.minY + from.y * rect.height))
        path.addLine(to: CGPoint(x: rect.minX + to.x * rect.width, y: rect.minY + to.y * rect.height))
        return path
    }
}

/// Side of a can or cone: straight sides, curved bottom.
private struct CurvedBottom: Shape {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let dip: CGFloat

    func path(in rect: CGRect) -> Path {
        func map(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
        }
        var path = Path()
        path.move(to: map(topLeft))
        path.addLine(to: map(bottomLeft))
        let middle = CGPoint(x: (bottomLeft.x + bottomRight.x) / 2, y: bottomLeft.y + dip)
        path.addQuadCurve(to: map(bottomRight), control: map(middle))
        path.addLine(to: map(topRight))
        path.closeSubpath()
        return path
    }
}

private func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some Shape {
    UnitEllipse(x: x, y: y, w: w, h: h)
}

private struct UnitEllipse: Shape {
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height,
                               width: w * rect.width, height: h * rect.height))
    }
}

/// Light and shaded faces with clear edges so children can count the sides.
struct SolidFigure: View {
    let solid: Solid
    var size: CGFloat = 120

    private let line: CGFloat = 2
    private let shade = Color.black.opacity(0.2)

    var body: some View {
        ZStack { figure }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var figure: some View {
        switch solid {
        case .cube: cube
        case .cylinder: cylinder
        case .sphere: sphere
        case .cone: cone
        case .pyramid: pyramid
        }
    }

    private func face(_ points: [(CGFloat, CGFloat)], _ color: Color, shaded: Bool = false) -> some View {
        let polygon = UnitPolygon(points: points.map { CGPoint(x: $0.0, y: $0.1) })
        return ZStack {
            polygon.fill(color)
            if shaded { polygon.fill(shade) }
            polygon.stroke(GeniColor.border, style: StrokeStyle(lineWidth: line, lineJoin: .round))
        }
    }

    private var cube: some View {
        ZStack {
            face([(0.07, 0.27), (0.5, 0.49), (0.5, 0.95), (0.07, 0.73)], GeniColor.blue)
            face([(0.5, 0.49), (0.93, 0.27), (0.93, 0.73), (0.5, 0.95)], GeniColor.blue, shaded: true)
            face([(0.5, 0.05), (0.93, 0.27), (0.5, 0.49), (0.07, 0.27)], GeniColor.cyan)
        }
    }

    private var pyramid: some View {
        let apex = CGPoint(x: 0.5, y: 0.05)
        let back = CGPoint(x: 0.6, y: 0.62)
        return ZStack {
            // Edges behind the pyramid, dashed, so all eight can be counted.
            let dashed = StrokeStyle(lineWidth: line - 1, lineCap: .round, dash: [5, 5])
            UnitLine(from: apex, to: back).stroke(GeniColor.border, style: dashed)
            UnitLine(from: CGPoint(x: 0.05, y: 0.78), to: back).stroke(GeniColor.border, style: dashed)
            UnitLine(from: CGPoint(x: 0.95, y: 0.74), to: back).stroke(GeniColor.border, style: dashed)
            face([(0.5, 0.05), (0.05, 0.78), (0.45, 0.95)], GeniColor.yellow)
            face([(0.5, 0.05), (0.45, 0.95), (0.95, 0.74)], GeniColor.orange)
        }
    }

    private var cylinder: some View {
        ZStack {
            CurvedBottom(topLeft: CGPoint(x: 0.18, y: 0.2), topRight: CGPoint(x: 0.82, y: 0.2),
                         bottomLeft: CGPoint(x: 0.18, y: 0.78), bottomRight: CGPoint(x: 0.82, y: 0.78), dip: 0.22)
                .fill(GeniColor.green)
            CurvedBottom(topLeft: CGPoint(x: 0.18, y: 0.2), topRight: CGPoint(x: 0.82, y: 0.2),
                         bottomLeft: CGPoint(x: 0.18, y: 0.78), bottomRight: CGPoint(x: 0.82, y: 0.78), dip: 0.22)
                .stroke(GeniColor.border, style: StrokeStyle(lineWidth: line, lineJoin: .round))
            ellipse(0.18, 0.08, 0.64, 0.24).fill(GeniColor.card)
            ellipse(0.18, 0.08, 0.64, 0.24).stroke(GeniColor.border, lineWidth: line)
        }
    }

    private var cone: some View {
        ZStack {
            ellipse(0.15, 0.68, 0.7, 0.24).fill(GeniColor.card)
            ellipse(0.15, 0.68, 0.7, 0.24).stroke(GeniColor.border, lineWidth: line)
            CurvedBottom(topLeft: CGPoint(x: 0.5, y: 0.05), topRight: CGPoint(x: 0.5, y: 0.05),
                         bottomLeft: CGPoint(x: 0.15, y: 0.8), bottomRight: CGPoint(x: 0.85, y: 0.8), dip: 0.22)
                .fill(GeniColor.pink)
            CurvedBottom(topLeft: CGPoint(x: 0.5, y: 0.05), topRight: CGPoint(x: 0.5, y: 0.05),
                         bottomLeft: CGPoint(x: 0.15, y: 0.8), bottomRight: CGPoint(x: 0.85, y: 0.8), dip: 0.22)
                .stroke(GeniColor.border, style: StrokeStyle(lineWidth: line, lineJoin: .round))
        }
    }

    private var sphere: some View {
        ZStack {
            ellipse(0.06, 0.06, 0.88, 0.88).fill(GeniColor.orange)
            ellipse(0.06, 0.06, 0.88, 0.88).stroke(GeniColor.border, lineWidth: line)
            ellipse(0.22, 0.2, 0.2, 0.14).fill(Color.white.opacity(0.7)).rotationEffect(.degrees(-35))
        }
    }
}
