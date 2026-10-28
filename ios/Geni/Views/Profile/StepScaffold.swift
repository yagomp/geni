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
        if iPadScale.isIPad {
            GeometryReader { available in
                let expanded = available.size.width >= 700
                let maxWidth: CGFloat = expanded ? (available.size.width > available.size.height ? 1120 : 1000) : 560
                scaffold(expanded: expanded, maxWidth: maxWidth)
            }
        } else {
            scaffold(expanded: false, maxWidth: 560)
        }
    }

    private func scaffold(expanded: Bool, maxWidth: CGFloat) -> some View {
        VStack(spacing: expanded ? 20 : 8) {
            topBar

            Text(title)
                .font(expanded ? .system(size: 40, weight: .black, design: .rounded) : .system(.title, design: .rounded, weight: .black))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .id(title)
                .transition(.opacity)
                .accessibilityAddTraits(.isHeader)

            // A single content tree keeps focus stable. Wide iPad steps fit without scrolling.
            GeometryReader { geo in
                if allowsScrolling && !expanded {
                    ScrollView {
                        content(geo.size)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.never)
                    // Selected tiles grow and carry a check dot past their edge.
                    .scrollClipDisabled()
                } else {
                    content(geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .padding(.horizontal, iPadScale.padding)
        .frame(maxWidth: maxWidth)
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 12) {
            primary
                .padding(.horizontal, iPadScale.padding)
                .padding(.bottom, 12)
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        }
        .environment(\.geniExpandedLayout, expanded)
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
                    .overlay(Capsule().stroke(GeniColor.hairline, lineWidth: 1))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(step) / \(total)")
    }
}

/// The step's green 72pt button. Disabled = pale green, never grey.
struct StepPrimaryButton: View {
    @Environment(\.geniExpandedLayout) private var expanded
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
                                     textColor: isEnabled ? .white : GeniColor.border,
                                     fontSize: expanded ? 30 : nil, verticalPadding: expanded ? 26 : nil))
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }
}
