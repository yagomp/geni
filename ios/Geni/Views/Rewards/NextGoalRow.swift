import SwiftUI

/// The closest unearned badge as one bordered row; tap opens its detail sheet.
struct NextGoalRow: View {
    let badge: Badge
    let progress: BadgeProgress?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                BadgeMedallion(badge: badge, size: 72, earned: false, progress: progress)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L.s(badge.titleKey))
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .lineLimit(2)
                    if let progress {
                        BadgeProgressView(progress: progress, color: badge.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(badge.color.deep())
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .softSurface(GeniColor.card)
        }
        .buttonStyle(KidPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.s(badge.titleKey))
        .accessibilityValue(L.s(badge.descriptionKey))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("rewards.next")
    }
}
