import SwiftUI

/// Calm profile tiles: soft depth at rest, then a tint, coloured outline and green ✓ dot.
struct SelectableTile: ViewModifier {
    let isSelected: Bool
    let tint: Color
    var restingFill: Color = GeniColor.card
    /// Defaults to `tint.soft(0.35)`; tiles whose fill is the picture (theme scenes) keep it.
    var selectedFill: Color? = nil
    var shapeScale: CGFloat = 0.6
    /// Retained for existing callers; every tile now uses the same subtle soft shadow.
    var restingShadow: Color = .clear
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shape = GeniShape(scale: shapeScale)
        content
            .softSurface(isSelected ? (selectedFill ?? tint.soft(0.35)) : restingFill, radiusScale: shapeScale)
            .overlay(shape.stroke(isSelected ? tint : GeniColor.hairline, lineWidth: isSelected ? 2 : 1).allowsHitTesting(false))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    SelectionCheckDot()
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected && !reduceMotion ? 1.04 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The green ✓ dot on selected tiles.
struct SelectionCheckDot: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(GeniColor.green))
            .overlay(Circle().stroke(GeniColor.hairline, lineWidth: 1))
            .accessibilityHidden(true)
    }
}

extension View {
    func selectableTile(isSelected: Bool, tint: Color, restingFill: Color = GeniColor.card, selectedFill: Color? = nil, shapeScale: CGFloat = 0.6, restingShadow: Color = .clear) -> some View {
        modifier(SelectableTile(isSelected: isSelected, tint: tint, restingFill: restingFill, selectedFill: selectedFill, shapeScale: shapeScale, restingShadow: restingShadow))
    }
}
