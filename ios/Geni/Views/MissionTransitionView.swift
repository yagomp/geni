import SwiftUI

struct MissionTransitionView: View {
    let mathStars: Int
    let mathCoins: Int
    let onContinue: () -> Void
    /// Set when reading is optional: offers ending the mission after math.
    var onFinish: (() -> Void)? = nil

    var body: some View {
        GeniLearningLayout {
            MissionTransitionViewLayout(mathStars: mathStars, mathCoins: mathCoins, onContinue: onContinue, onFinish: onFinish)
        }
    }
}

private struct MissionTransitionViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let mathStars: Int
    let mathCoins: Int
    let onContinue: () -> Void
    /// Set when reading is optional: offers ending the mission after math.
    var onFinish: (() -> Void)? = nil

    var body: some View {
        CompletionScaffold(mascot: .pose(.point), title: L.s(.greatJobMath), background: GeniColor.lightYellow, confetti: false) {
            VStack(spacing: expanded ? 12 : 8) {
                CompletionStars(stars: mathStars)

                HStack(spacing: 4) {
                    Text("🪙")
                    Text("+\(mathCoins)")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
            }

            VStack(spacing: 8) {
                Text("📖")
                    .font(.system(size: expanded ? 54 : 36))

                Text(L.s(.nowLetsRead))
                    .font(.system(expanded ? .largeTitle : .title2, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)
                    .multilineTextAlignment(.center)
            }
            .completionCard()
        } actions: {
            CompletionButton(title: L.s(onFinish == nil ? .continueToReading : .startReading), color: GeniColor.green,
                             showsPlay: true, identifier: "missionTransition.continue", action: onContinue)

            if let onFinish {
                CompletionButton(title: L.s(.done), color: GeniColor.card, textColor: GeniColor.border,
                                 isPrimary: false, identifier: "missionTransition.finish", action: onFinish)
            }
        }
        .onAppear { HapticManager.notification(.success) }
    }
}
