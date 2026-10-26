import SwiftUI

/// Spec §0 selected state for kid tiles: tinted fill, coloured offset shadow, green ✓ dot,
/// a small spring scale. Resting: card fill and black outline, with an optional black shadow.
struct SelectableTile: ViewModifier {
    let isSelected: Bool
    let tint: Color
    var restingFill: Color = GeniColor.card
    /// Defaults to `tint.soft(0.55)`; tiles whose fill is the picture (theme scenes) keep it.
    var selectedFill: Color? = nil
    var shapeScale: CGFloat = 0.6
    var restingShadow: Color = .clear
    @Environment(\.geniCornerRadius) private var radiusOverride
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shape = GeniShape(scale: shapeScale, override: radiusOverride)
        content
            .background(isSelected ? (selectedFill ?? tint.soft(0.55)) : restingFill)
            .clipShape(shape)
            .overlay(shape.stroke(GeniColor.border, lineWidth: 3))
            .background(shape.fill(isSelected ? tint.deep() : restingShadow).offset(x: 4, y: 4))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    SelectionCheckDot()
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected && !reduceMotion ? 1.06 : 1)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.55), value: isSelected)
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
            .overlay(Circle().stroke(GeniColor.border, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

extension View {
    func selectableTile(isSelected: Bool, tint: Color, restingFill: Color = GeniColor.card, selectedFill: Color? = nil, shapeScale: CGFloat = 0.6, restingShadow: Color = .clear) -> some View {
        modifier(SelectableTile(isSelected: isSelected, tint: tint, restingFill: restingFill, selectedFill: selectedFill, shapeScale: shapeScale, restingShadow: restingShadow))
    }
}
