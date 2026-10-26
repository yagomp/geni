import SwiftUI

/// A number shown as raised fingers (two hands above 5). The child taps the numeral or,
/// when `object` is set, the tile with that many objects.
nonisolated struct FingerPayload: GamePayload {
    let count: Int
    let choices: [Int]
    let object: String?
}

extension EarlyYearsGames {
    static let fingerObjects = ["🍎", "⭐", "🎈", "🍓", "🐞", "🌸", "⚽", "🍪"]

    static func fingerNumbers(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let range: ClosedRange<Int>
        let choiceCount: Int
        var objects = false
        switch (difficulty, age >= 5) {
        case (.warmup, false):
            range = 1...3; choiceCount = 3; objects = true
        case (.warmup, true), (.normal, false):
            range = 1...5; choiceCount = 3; objects = Bool.random()
        case (.harder, false):
            range = 2...5; choiceCount = 3; objects = Bool.random()
        case (.challenge, false), (.normal, true):
            range = 1...5; choiceCount = 4
        case (.harder, true):
            range = 4...8; choiceCount = 4
        case (.challenge, true):
            range = 6...10; choiceCount = 4
        }
        let count = Int.random(in: range)
        let pool = 1...max(range.upperBound, 5)
        let choices = nearby(count, count: choiceCount, in: pool)
        let object = objects ? fingerObjects.randomElement()! : nil
        return Exercise(
            game: GameSpec(kind: .fingerNumbers,
                           prompt: L.t("How many fingers?", no: "Hvor mange fingre?", es: "¿Cuántos dedos?", pt: "Quantos dedos?"),
                           answerText: object.map { String(repeating: $0, count: count) } ?? "\(count)",
                           payload: FingerPayload(count: count, choices: choices, object: object)),
            correctAnswer: count,
            options: choices,
            difficulty: difficulty
        )
    }
}

struct FingerGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: FingerPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        let unit: CGFloat = (payload.count > 5 ? 0.95 : 1.15) * (expanded ? 1.6 : iPadScale.factor)
        VStack(spacing: expanded ? 36 : 24) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                HStack(spacing: 16 * unit) {
                    if payload.count > 5 {
                        DrawnHand(raised: 5, unit: unit).scaleEffect(x: -1)
                        DrawnHand(raised: payload.count - 5, unit: unit)
                    } else {
                        DrawnHand(raised: payload.count, unit: unit)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(spec.prompt)
            }
            if let object = payload.object {
                HStack(spacing: 12) {
                    ForEach(payload.choices, id: \.self) { value in
                        GameChoiceTile(value: value, exercise: exercise, chapterVM: chapterVM, persistence: persistence) {
                            ObjectGroup(object: object, count: value)
                        }
                    }
                }
            } else {
                GameChoices(choices: payload.choices.map { GameChoice(label: "\($0)", value: $0) },
                            exercise: exercise, chapterVM: chapterVM, persistence: persistence)
            }
        }
    }
}

/// Up to five objects in rows of three, easy to count at a glance.
private struct ObjectGroup: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let object: String
    let count: Int

    var body: some View {
        let rows = stride(from: 0, to: count, by: 3).map { min(3, count - $0) }
        VStack(spacing: 2) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, n in
                Text(String(repeating: object, count: n))
                    .font(.system(size: expanded ? 36 : iPadScale.value(24)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityLabel("\(count)")
    }
}

/// A cartoon right hand, palm out, thumb on the left. Raised fingers stand tall; folded ones
/// show only a knuckle. Fingers go up in counting order: index, middle, ring, little, thumb.
/// Drawn on a 110 × 130 grid times `unit`; mirror with `.scaleEffect(x: -1)` for a left hand.
struct DrawnHand: View {
    let raised: Int
    let unit: CGFloat

    private let fingerX: [CGFloat] = [35, 51, 67, 83]
    private let fingerTop: [CGFloat] = [18, 8, 14, 28]

    var body: some View {
        let thumbUp = raised >= 5
        let thumbLength: CGFloat = thumbUp ? 46 : 26
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let top = raised > i ? fingerTop[i] : 56
                part(Capsule(), x: fingerX[i], y: (top + 80) / 2, width: 16, height: 80 - top)
            }
            // Rotates around its base on the side of the palm.
            part(Capsule(), x: 32, y: 112 - thumbLength / 2, width: 17, height: thumbLength, angle: thumbUp ? -40 : -25)
            part(RoundedRectangle(cornerRadius: 24 * unit), x: 60, y: 96, width: 68, height: 64)
        }
        .frame(width: 110 * unit, height: 130 * unit)
        .accessibilityHidden(true)
    }

    private func part<S: InsettableShape>(_ shape: S, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                                         angle: Double = 0) -> some View {
        shape
            .fill(GeniColor.yellow)
            .overlay(shape.strokeBorder(GeniColor.orange.deep(0.15), lineWidth: 1.5))
            .frame(width: width * unit, height: height * unit)
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .position(x: x * unit, y: y * unit)
    }
}
