import SwiftUI

struct BadgeDetailSheet: View {
    let badge: Badge
    let rewards: RewardState
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let earned = badge.isEarned(in: rewards)
        let progress = badge.progress(in: rewards)

        ScrollView {
            VStack(spacing: 16) {
                BadgeMedallion(badge: badge, size: 120, earned: earned, progress: progress)

                Text(L.s(badge.titleKey))
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)
                    .multilineTextAlignment(.center)

                Text(L.s(badge.descriptionKey))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(GeniColor.border)
                    .multilineTextAlignment(.center)

                if !earned, let progress {
                    BadgeProgressView(progress: progress, color: badge.color)
                        .frame(maxWidth: 280)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: SheetContentHeightKey.self, value: proxy.size.height)
                }
            }
        }
        .background(GeniColor.lightYellow.ignoresSafeArea())
        .onPreferenceChange(SheetContentHeightKey.self) { contentHeight = $0 }
        .presentationDetents([contentHeight > 0 ? .height(contentHeight) : .medium])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("rewards.badgeDetail")
    }
}

private struct SheetContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
