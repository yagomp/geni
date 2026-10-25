import SwiftUI

/// A consistently gold coin, independent of the platform's emoji artwork.
struct CoinIcon: View {
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .fill(GeniColor.yellow)
            .overlay(Circle().strokeBorder(GeniColor.orange.deep(0.15), lineWidth: size * 0.1))
            .overlay {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.43, weight: .black))
                    .foregroundStyle(GeniColor.orange.deep(0.3))
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
