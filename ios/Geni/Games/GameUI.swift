import SwiftUI

// Shared building blocks for every game, so all of them look and behave the same:
// one question line, one picture card, 2–4 big tiles. Tapping a tile answers.
//
// Look (docs/games/DESIGN.md): calm and round. White surfaces with a soft shadow and a pale
// hairline instead of black borders and hard offset shadows; anything tappable has a 4pt
// bottom edge that flattens when pressed; colour is reserved for feedback (green/pink).

/// Visual tokens for game screens. Custom game pieces use these so they match the shared tiles.
enum GameStyle {
    /// Rounded corner radius for cards and tiles.
    static func radius(expanded: Bool) -> CGFloat {
        return expanded ? 24 * 1.3 : 24
    }

    /// Radius for small cells (grids, frames) as a fraction of their size.
    static func cellRadius(_ size: CGFloat, _ fraction: CGFloat = 0.25) -> CGFloat {
        size * fraction
    }
    /// Pale outline so white sits cleanly on the cream background.
    static let hairline = GeniColor.border.opacity(0.10)
    /// Resting bottom edge of a tappable tile ("you can press this").
    static let edge = GeniColor.border.opacity(0.14)
    static let edgeHeight: CGFloat = 4
    static let shadow = GeniColor.border.opacity(0.08)
    /// Spacing scale: 4 · 8 · 12 · 16 · 24 · 32.
    static func gap(_ base: CGFloat, expanded: Bool) -> CGFloat { expanded ? base * 1.5 : base }
}

extension EnvironmentValues {
    /// Space the exercise screen leaves for the current exercise's content: the scroll area under the
    /// header, minus the content's own padding and the footer reserve. `.zero` outside an exercise.
    @Entry var geniExerciseViewport: CGSize = .zero
}

/// A white (theme card) surface: rounded, hairline, soft shadow. For picture cards, counters, trays.
struct GameSurface: ViewModifier {
    @Environment(\.geniExpandedLayout) private var expanded
    var color: Color

    func body(content: Content) -> some View {
        let shape = GeniShape(radius: GameStyle.radius(expanded: expanded))
        content
            .background(color, in: shape)
            .overlay(shape.stroke(GameStyle.hairline, lineWidth: 2).allowsHitTesting(false))
            .compositingGroup()
            .shadow(color: GameStyle.shadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func gameSurface(_ color: Color = GeniColor.card) -> some View {
        modifier(GameSurface(color: color))
    }
}

/// The tappable look: fill, pale outline, a bottom edge that the tile sinks into when pressed.
/// Used by the shared tiles and the ✓ button; custom pieces (coins, blocks) can use it too.
struct GameTileStyle: ButtonStyle {
    @Environment(\.geniExpandedLayout) private var expanded
    var fill: Color = GeniColor.card
    var outline: Color = GameStyle.hairline
    var edge: Color = GameStyle.edge

    func makeBody(configuration: Configuration) -> some View {
        let shape = GeniShape(radius: GameStyle.radius(expanded: expanded))
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(fill.readableText)
            .contentShape(Rectangle())
            .background(fill, in: shape)
            .overlay(shape.stroke(outline, lineWidth: 2).allowsHitTesting(false))
            .background(shape.fill(edge).offset(y: pressed ? 1 : GameStyle.edgeHeight))
            .compositingGroup()
            .shadow(color: GameStyle.shadow, radius: pressed ? 2 : 8, x: 0, y: pressed ? 1 : 3)
            .offset(y: pressed ? GameStyle.edgeHeight - 1 : 0)
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: pressed)
    }
}

/// The question above every game, with room for longer story prompts.
struct GameQuestion: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let text: String

    private var fontSize: CGFloat {
        let isLongPrompt = text.count > 45
        return expanded ? (isLongPrompt ? 34 : 44) : iPadScale.value(isLongPrompt ? 22 : 28)
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(GeniColor.border)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
    }
}

/// The white card the picture sits on.
/// `framed: false` for pictures that are their own container (grids, frames): no box inside a box.
struct GameSceneCard<Content: View>: View {
    @Environment(\.geniExpandedLayout) private var expanded
    var framed = true
    @ViewBuilder let content: Content

    var body: some View {
        if framed {
            content
                .padding(expanded ? 28 : 16)
                .frame(maxWidth: .infinity)
                .gameSurface(GeniColor.card)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}

/// A row of big pictures (emoji or short labels).
struct GameEmojiRow: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let items: [String]

    var body: some View {
        HStack(spacing: expanded ? 16 : 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(.system(size: expanded ? 64 : iPadScale.value(40), weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Where a tile can be dropped to answer (a gap in the picture), in global coordinates.
struct GameDropTarget {
    let frame: CGRect
    /// Told whether a dragged tile is over the target, so the target can light up.
    var hover: (Bool) -> Void = { _ in }

    /// Generous for small fingers: the finger only has to land near the gap.
    func contains(_ point: CGPoint) -> Bool {
        !frame.isEmpty && frame.insetBy(dx: -24, dy: -24).contains(point)
    }
}

/// A tile that answers with `value` when tapped, and turns green/pink with the feedback.
/// With a `dropTarget` it can also be dragged: released over the target it answers like a tap,
/// anywhere else it springs back.
struct GameChoiceTile<Label: View>: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let value: Int
    let exercise: Exercise
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    var height: CGFloat = 88
    var dropTarget: GameDropTarget? = nil
    @ViewBuilder let label: Label
    @State private var dragOffset: CGSize = .zero

    private enum Feedback { case idle, correct, wrong, faded }

    var body: some View {
        let feedback = self.feedback
        Button {
            answer()
        } label: {
            label
                .frame(maxWidth: .infinity)
                .frame(height: expanded ? height * 1.6 : iPadScale.value(height))
        }
        .buttonStyle(GameTileStyle(fill: background, outline: outline, edge: edge))
        .disabled(chapterVM.showFeedback)
        .opacity(feedback == .faded ? 0.5 : 1)
        .scaleEffect(feedback == .correct ? 1.04 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: feedback)
        .offset(dragOffset)
        .zIndex(dragOffset == .zero ? 0 : 1)
        // A tap stays a tap (the drag needs 10 pt of movement); without a target the tile only taps.
        .highPriorityGesture(drag, including: dropTarget == nil || chapterVM.showFeedback ? .subviews : .all)
        .accessibilityIdentifier("answer.\(value)")
    }

    private func answer() {
        guard !chapterVM.showFeedback else { return }
        HapticManager.impact(.medium)
        chapterVM.submitAnswer(value, persistence: persistence)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { drag in
                dragOffset = drag.translation
                dropTarget?.hover(dropTarget?.contains(drag.location) == true)
            }
            .onEnded { drag in
                dropTarget?.hover(false)
                if dropTarget?.contains(drag.location) == true { answer() }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { dragOffset = .zero }
            }
    }

    private var feedback: Feedback {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else { return .idle }
        if value == exercise.correctAnswer && (chapterVM.feedbackCorrect || chapterVM.showAnswer) { return .correct }
        if value == selected && !chapterVM.feedbackCorrect { return .wrong }
        return .faded
    }

    private var background: Color {
        switch feedback {
        case .correct: return GeniColor.green
        case .wrong: return GeniColor.pink.soft(0.3)
        case .idle, .faded: return GeniColor.card
        }
    }

    private var outline: Color {
        switch feedback {
        case .correct: return GeniColor.green.deep(0.25)
        case .wrong: return GeniColor.pink
        case .idle, .faded: return GameStyle.hairline
        }
    }

    private var edge: Color {
        switch feedback {
        case .correct: return GeniColor.green.deep(0.3)
        case .wrong: return GeniColor.pink.soft(0.6)
        case .idle, .faded: return GameStyle.edge
        }
    }
}

/// For build-then-check games (pay with coins, build a number, arrange arrows): one big ✓ that
/// answers with whatever the child built. Same look and feedback as the tiles.
struct GameSubmitButton: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let value: Int
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    var isEnabled = true

    var body: some View {
        Button {
            guard !chapterVM.showFeedback else { return }
            HapticManager.impact(.medium)
            chapterVM.submitAnswer(value, persistence: persistence)
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: expanded ? 44 : iPadScale.value(30), weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: expanded ? 110 : iPadScale.value(72))
        }
        .buttonStyle(GameTileStyle(
            fill: isEnabled ? GeniColor.green : GeniColor.lightGray,
            outline: .clear,
            edge: isEnabled ? GeniColor.green.deep(0.3) : GameStyle.edge
        ))
        .disabled(!isEnabled || chapterVM.showFeedback)
        .animation(.easeOut(duration: 0.15), value: isEnabled)
        .accessibilityLabel(L.t("Check", no: "Sjekk", es: "Comprobar", pt: "Verificar"))
        .accessibilityIdentifier("game.submit")
    }
}

/// 2–4 tiles in one row (two rows of two for long labels).
struct GameChoices: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let choices: [GameChoice]
    let exercise: Exercise
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        let longest = choices.map(\.label.count).max() ?? 0
        // Pictures (emoji) are the answer itself for the youngest: draw them big
        let pictures = choices.allSatisfy { $0.label.unicodeScalars.contains { $0.properties.isEmojiPresentation } &&
            !$0.label.contains(where: { $0.isLetter || $0.isNumber }) }
        let columns = choices.count == 4 && longest > 3 ? 2 : choices.count
        let gap = GameStyle.gap(14, expanded: expanded)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: max(columns, 1)), spacing: gap) {
            ForEach(choices, id: \.value) { choice in
                GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM, persistence: persistence) {
                    Text(choice.label)
                        .font(.system(size: pictures ? (expanded ? 72 : iPadScale.value(52))
                                      : expanded ? 52 : iPadScale.value(longest > 3 ? 24 : 36), weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 6)
                }
            }
        }
    }
}

/// The default game screen: question, picture card, choices.
struct ChoiceGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: ChoicePayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        VStack(spacing: GameStyle.gap(24, expanded: expanded)) {
            GameQuestion(text: spec.prompt)
            if !payload.scene.isEmpty {
                GameSceneCard {
                    VStack(spacing: expanded ? 16 : 10) {
                        ForEach(Array(payload.scene.enumerated()), id: \.offset) { _, row in
                            GameEmojiRow(items: row)
                        }
                    }
                }
            }
            GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }
}

/// Routes a game exercise to its folder's view.
struct GameExerciseView: View {
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        switch spec.kind {
        case .ordinal, .position, .fingerNumbers, .bigSmall:
            EarlyYearsGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .patternNext, .shapeFind, .oddOneOut:
            ShapeGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .tenFriends, .doubles, .numberNeighbours, .countBackwards, .skipCounting:
            NumberSenseGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .moneyPay, .moneyChange, .moneyShopping:
            MoneyGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .numberLine, .tensOnes:
            PlaceValueGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .weekdays, .seasons, .units, .shapes3D:
            CalendarGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .codingPath, .codingLoop, .symmetry:
            CodingGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .tallyChart, .barChart, .estimate:
            DataGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        case .timesGroups, .fairShare, .storyMatch:
            StoryGameView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
        }
    }
}
