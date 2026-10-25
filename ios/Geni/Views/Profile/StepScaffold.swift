import SwiftUI

/// One onboarding step: back | progress dots, a title, centred content, and a 72pt primary
/// button pinned above the keyboard. The avatar grid gets the available size without a
/// scroll view; other steps can scroll if needed at accessibility sizes.
struct StepScaffold<Content: View>: View {
    let step: Int
    var total: Int = 3
    let title: String
    let accent: Color
    /// Nil hides the back button.
    let onBack: (() -> Void)?
    let primary: StepPrimaryButton
    var allowsScrolling = true
    @ViewBuilder let content: (CGSize) -> Content

    var body: some View {
        VStack(spacing: 8) {
            topBar

            Text(title)
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .id(title)
                .transition(.opacity)
                .accessibilityAddTraits(.isHeader)

            // A fixed-size layout when it fits; scrolls (without bouncing) only when it can't.
            // ViewThatFits would build the content twice, duplicating the focused name field.
            GeometryReader { geo in
                if allowsScrolling {
                    ScrollView {
                        content(geo.size)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.never)
                    // Selected tiles grow and carry a ✓ dot past their edge; don't cut them off.
                    .scrollClipDisabled()
                } else {
                    content(geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .padding(.horizontal, iPadScale.padding)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 12) {
            primary
                .padding(.horizontal, iPadScale.padding)
                .padding(.bottom, 12)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
        }
    }

    private var topBar: some View {
        HStack {
            if let onBack {
                KidBackButton(action: onBack)
                    .accessibilityIdentifier("profile.back")
            } else {
                Color.clear.frame(width: 56, height: 56)
            }
            Spacer()
            StepDots(step: step, total: total, accent: accent)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .frame(height: 56)
    }
}

/// 12pt progress dots: current = accent pill, done = green, upcoming = white.
struct StepDots: View {
    let step: Int
    let total: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i == step ? accent : (i < step ? GeniColor.green : .white))
                    .frame(width: i == step ? 36 : 12, height: 12)
                    .overlay(Capsule().stroke(GeniColor.border, lineWidth: 2))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(step) / \(total)")
    }
}

/// The step's green 72pt button. Disabled = pale green, never grey.
struct StepPrimaryButton: View {
    let title: String
    var showsPlay = false
    var color: Color = GeniColor.green
    let isEnabled: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.medium)
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showsPlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .black))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(BrutalistButton(color: isEnabled ? color : color.soft(0.35),
                                     textColor: isEnabled ? .white : GeniColor.border))
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }
}
