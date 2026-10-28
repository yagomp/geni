import SwiftUI

/// What Geni does at the top of a completion screen.
enum CompletionMascot {
    /// The cheer clip once, then the idle loop.
    case cheer
    /// A still pose that springs up once.
    case pose(MascotPose)
}

/// The one layout of the screens that end an activity (chapter, reading and mission complete, and the
/// math→reading transition): Geni, the title and the screen's own cards, vertically centred above the call to
/// action, which sits at the same place, width and height on every one of them. Use inside `GeniLearningLayout`.
struct CompletionScaffold<Content: View, Actions: View>: View {
    let mascot: CompletionMascot
    let title: String
    var background: Color = GeniColor.background
    var confetti = true
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions

    @Environment(\.geniExpandedLayout) private var expanded
    @Environment(\.geniLearningSize) private var size
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showConfetti = false

    /// The idle frame (`HeroMascot`, the clips' boundary pose) is 934 px tall; Geni fills 858 px of it and stands
    /// 13 px above its bottom edge. Stills are scaled to that figure so every screen shows Geni the same size.
    private static var figureFraction: CGFloat { 858.0 / 934.0 }
    private static var feetInset: CGFloat { 13.0 / 934.0 }

    private var spacing: CGFloat { expanded ? 28 : 14 }
    private var maxWidth: CGFloat { expanded ? 680 : 560 }
    /// Height of Geni's slot: smaller on short phones so the cards still fit above the button.
    private var mascotSlot: CGFloat {
        expanded ? 240 : min(150, max(88, size.height * 0.16))
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                GeometryReader { scroll in
                    ScrollView {
                        VStack(spacing: spacing) {
                            mascotView
                                .frame(height: mascotSlot, alignment: .bottom)

                            Text(title)
                                .font(.system(size: expanded ? 48 : 32, weight: .black, design: .rounded))
                                .foregroundStyle(GeniColor.border)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                            VStack(spacing: spacing) { content }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared || reduceMotion ? 0 : 40)
                                .animation(.spring(response: 0.5).delay(0.35), value: appeared)
                        }
                        .padding(.vertical, spacing)
                        .frame(maxWidth: maxWidth)
                        .padding(.horizontal, iPadScale.padding)
                        .frame(maxWidth: .infinity, minHeight: scroll.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    // Short phones scroll the longest screens: show that there is more, and let the cards
                    // fade out above the button instead of being cut off. Content that fits never reaches the fade.
                    .scrollIndicatorsFlash(onAppear: true)
                    .mask {
                        VStack(spacing: 0) {
                            Color.black
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: spacing)
                        }
                    }
                }

                VStack(spacing: expanded ? 20 : 12) { actions }
                    .frame(maxWidth: maxWidth)
                    .padding(.horizontal, iPadScale.padding)
                    .padding(.top, 12)
                    .padding(.bottom, iPadScale.value(36))
                    .frame(maxWidth: .infinity)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.7), value: appeared)
            }
            .foregroundStyle(.black)
        }
        .onAppear { appeared = true }
        .task {
            guard confetti else { return }
            do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
            showConfetti = true
        }
    }

    @ViewBuilder
    private var mascotView: some View {
        switch mascot {
        case .cheer:
            MascotCheerView(height: mascotSlot)
        case .pose(let pose):
            MascotPoseView(pose: pose, height: mascotSlot * Self.figureFraction)
                .padding(.bottom, mascotSlot * Self.feetInset)
        }
    }
}

/// The completion screens' call to action: the app's primary button metrics, the same on every screen.
struct CompletionButton: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let title: String
    let color: Color
    var textColor: Color? = nil
    var showsPlay = false
    var isPrimary = true
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button {
            if isPrimary { HapticManager.impact(.medium) } else { HapticManager.selection() }
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showsPlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: expanded ? 24 : 18, weight: .black))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(BrutalistButton(color: color, textColor: textColor,
                                     fontSize: expanded ? 30 : nil, verticalPadding: expanded ? 26 : nil))
        .accessibilityIdentifier(identifier)
    }
}

/// Five stars, earned ones filled, at the completion screens' shared size.
struct CompletionStars: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let stars: Int

    var body: some View {
        HStack(spacing: expanded ? 12 : 8) {
            ForEach(1...5, id: \.self) { star in
                Text(star <= stars ? "⭐" : "☆")
                    .font(.system(size: expanded ? 44 : 30))
                    .foregroundStyle(star <= stars ? GeniColor.yellow : .gray.opacity(0.3))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) / 5")
    }
}

extension View {
    /// The completion screens' white card: full content width, shared padding.
    func completionCard() -> some View {
        modifier(CompletionCard())
    }
}

private struct CompletionCard: ViewModifier {
    @Environment(\.geniExpandedLayout) private var expanded

    func body(content: Content) -> some View {
        content
            .padding(expanded ? 32 : 18)
            .frame(maxWidth: .infinity)
            .softSurface(GeniColor.card)
    }
}
