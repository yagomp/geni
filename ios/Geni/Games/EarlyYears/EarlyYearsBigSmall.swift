import SwiftUI

/// The same picture in clearly different sizes, or snakes of different lengths when `item` is nil.
/// `sizes` are relative (largest 1); answer tile i has value i + 1.
nonisolated struct BigSmallPayload: GamePayload {
    let item: String?
    let sizes: [Double]
}

extension EarlyYearsGames {
    static let sizeItems = ["🍎", "🐻", "🎈", "🐟", "🌳", "🐶", "⭐", "🧸", "🍓", "🐘", "🚗", "🍦"]

    private enum Ask { case biggest, smallest, longest, shortest }

    static func bigSmall(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let count = difficulty == .warmup ? 2 : 3
        let asks: [Ask]
        switch difficulty {
        case .warmup, .normal: asks = [.biggest, .smallest]
        case .harder: asks = [.biggest, .smallest, .longest]
        case .challenge: asks = [.biggest, .smallest, .longest, .shortest]
        }
        let ask = asks.randomElement()!
        // Each size at least 1.4× the one before, so the difference is plain to see.
        let steps: [Double] = count == 2 ? [0.5, 1] : difficulty == .challenge ? [0.48, 0.7, 1] : [0.4, 0.68, 1]
        let sizes = steps.shuffled()
        let isLength = ask == .longest || ask == .shortest
        let item = isLength ? nil : sizeItems.randomElement()!
        let index = ask == .biggest || ask == .longest
            ? sizes.firstIndex(of: 1)!
            : sizes.firstIndex(of: steps[0])!
        let prompt: String
        switch ask {
        case .biggest:
            prompt = L.t("Which one is the biggest?", no: "Hvilken er størst?", es: "¿Cuál es el más grande?", pt: "Qual é o maior?")
        case .smallest:
            prompt = L.t("Which one is the smallest?", no: "Hvilken er minst?", es: "¿Cuál es el más pequeño?", pt: "Qual é o mais pequeno?")
        case .longest:
            prompt = L.t("Which snake is the longest?", no: "Hvilken slange er lengst?",
                         es: "¿Qué serpiente es la más larga?", pt: "Qual é a cobra mais comprida?")
        case .shortest:
            prompt = L.t("Which snake is the shortest?", no: "Hvilken slange er kortest?",
                         es: "¿Qué serpiente es la más corta?", pt: "Qual é a cobra mais curta?")
        }
        return Exercise(
            game: GameSpec(kind: .bigSmall, prompt: prompt, answerText: item ?? "🐍",
                           payload: BigSmallPayload(item: item, sizes: sizes)),
            correctAnswer: index + 1,
            options: Array(1...count),
            difficulty: difficulty
        )
    }
}

struct BigSmallGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: BigSmallPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    private var s: CGFloat { expanded ? 1.6 : iPadScale.factor }

    var body: some View {
        VStack(spacing: expanded ? 36 : 24) {
            GameQuestion(text: spec.prompt)
            if let item = payload.item {
                HStack(spacing: GameStyle.gap(14, expanded: expanded)) {
                    ForEach(Array(payload.sizes.enumerated()), id: \.offset) { index, size in
                        GameChoiceTile(value: index + 1, exercise: exercise, chapterVM: chapterVM,
                                       persistence: persistence, height: 152) {
                            Text(item)
                                .font(.system(size: 80 * s * size))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 16 * s)
                        }
                    }
                }
            } else {
                VStack(spacing: GameStyle.gap(14, expanded: expanded)) {
                    ForEach(Array(payload.sizes.enumerated()), id: \.offset) { index, size in
                        GameChoiceTile(value: index + 1, exercise: exercise, chapterVM: chapterVM,
                                       persistence: persistence, height: 64) {
                            GeometryReader { geometry in
                                DrawnSnake(color: Self.snakeColors[index % Self.snakeColors.count], height: 28 * s)
                                    .frame(width: geometry.size.width * size)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16 * s)
                        }
                    }
                }
            }
        }
    }

    private static let snakeColors = [GeniColor.green, GeniColor.orange, GeniColor.blue]
}

/// A long round body with an eye at the head end (right).
private struct DrawnSnake: View {
    let color: Color
    let height: CGFloat

    var body: some View {
        Capsule()
            .fill(color)
            .overlay(Capsule().strokeBorder(color.deep(0.25), lineWidth: 1.5))
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(.white)
                    .overlay(Circle().fill(GeniColor.border).padding(height * 0.12))
                    .overlay(Circle().stroke(GeniColor.border, lineWidth: 2))
                    .frame(width: height * 0.42, height: height * 0.42)
                    .padding(.trailing, height * 0.38)
            }
            .frame(height: height)
            .accessibilityLabel("🐍")
    }
}
