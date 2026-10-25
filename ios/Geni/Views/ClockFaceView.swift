import SwiftUI

/// A clock shared by reading, matching and setting activities.
/// Drag a coloured tip: hours select whole hours, minutes snap to the lesson's step.
struct ClockFaceView: View {
    let time: ClockTime
    var minuteStep: Int = 1
    var onChange: ((ClockTime) -> Void)? = nil
    @State private var draggingHour: Bool?

    private let navy = Color(red: 0.12, green: 0.22, blue: 0.40)
    private let hourColor = Color(red: 0.85, green: 0.12, blue: 0.38)
    private let minuteColor = Color(red: 0.0, green: 0.36, blue: 0.86)

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = side / 2 - 4
            let hourTip = point(angle: time.hourAngle, radius: radius * 0.44, center: center)
            let minuteTip = point(angle: time.minuteAngle, radius: radius * 0.72, center: center)
            ZStack {
                Circle().fill(.white)
                    .overlay(Circle().stroke(GeniColor.border, lineWidth: max(2, side * 0.015)))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                ForEach(0..<60, id: \.self) { tick in
                    Path { path in
                        path.move(to: point(angle: Double(tick) * 6, radius: radius * (tick % 5 == 0 ? 0.86 : 0.91), center: center))
                        path.addLine(to: point(angle: Double(tick) * 6, radius: radius * 0.96, center: center))
                    }
                    .stroke(navy.opacity(tick % 5 == 0 ? 1 : 0.5), lineWidth: tick % 5 == 0 ? 2 : 1)
                }
                ForEach(1...12, id: \.self) { number in
                    Text("\(number)")
                        .font(.system(size: max(10, side * 0.078), weight: .black, design: .rounded))
                        .foregroundStyle(navy)
                        .position(point(angle: Double(number) * 30, radius: radius * 0.73, center: center))
                }
                hand(from: center, to: hourTip, color: hourColor, width: side * 0.042)
                hand(from: center, to: minuteTip, color: minuteColor, width: side * 0.024)
                Circle().fill(GeniColor.yellow).overlay(Circle().stroke(navy, lineWidth: 2))
                    .frame(width: side * 0.065, height: side * 0.065).position(center)
                if onChange != nil {
                    handle(at: hourTip, color: hourColor, isHour: true, side: side)
                    if minuteStep < 60 {
                        handle(at: minuteTip, color: minuteColor, isHour: false, side: side)
                    }
                }
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard let onChange else { return }
                    if draggingHour == nil {
                        draggingHour = distance(value.startLocation, hourTip) < distance(value.startLocation, minuteTip)
                    }
                    guard distance(value.location, center) > radius * 0.15 else { return }
                    let angle = atan2(value.location.x - center.x, center.y - value.location.y) * 180 / .pi
                    let next = draggingHour == true ? time.settingHour(angle: angle) : time.settingMinute(angle: angle, step: minuteStep)
                    if next != time { HapticManager.selection(); onChange(next) }
                }
                .onEnded { _ in draggingHour = nil }, including: onChange == nil ? .none : .all)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: onChange == nil ? .ignore : .contain)
        .accessibilityLabel(onChange == nil ? time.digital : L.s(.clockSet))
    }

    private func point(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(x: center.x + sin(radians) * radius, y: center.y - cos(radians) * radius)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private func hand(from start: CGPoint, to end: CGPoint, color: Color, width: CGFloat) -> some View {
        Path { path in path.move(to: start); path.addLine(to: end) }
            .stroke(color, style: StrokeStyle(lineWidth: max(2, width), lineCap: .round))
    }

    private func handle(at point: CGPoint, color: Color, isHour: Bool, side: CGFloat) -> some View {
        Circle().fill(color).overlay(Circle().stroke(.white, lineWidth: 2))
            .frame(width: max(12, side * 0.06), height: max(12, side * 0.06))
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .position(point)
            .accessibilityElement()
            .accessibilityLabel(L.s(isHour ? .clockHourHand : .clockMinuteHand))
            .accessibilityValue(isHour ? "\(time.hour)" : "\(time.minute)")
            .accessibilityIdentifier(isHour ? "clock.hourHand" : "clock.minuteHand")
            .accessibilityAdjustableAction { direction in
                let delta = direction == .increment ? 1 : -1
                let next = isHour ? ClockTime(hour: time.hour + delta, minute: time.minute)
                    : time.settingMinute(angle: Double(time.minute + delta * minuteStep) * 6, step: minuteStep)
                onChange?(next)
            }
    }
}
