import SwiftUI

/// Where an animal sits around the table. Left/right are as the child sees the screen.
nonisolated enum TableSpot: Sendable, CaseIterable {
    case on, under, left, right
}

/// Animals around a drawn table; answer tile i has value i + 1.
nonisolated struct PositionPayload: GamePayload {
    let animals: [String]
    let spots: [TableSpot]
}

extension EarlyYearsGames {
    static let tableAnimals = ["🐶", "🐱", "🐰", "🐻", "🐸", "🐵", "🐼", "🦊", "🐷", "🐭", "🐨", "🐯"]

    private enum Ask { case on, under, nextTo, left, right }

    static func position(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let side: TableSpot = Bool.random() ? .left : .right
        let spots: [TableSpot]
        let asks: [Ask]
        switch difficulty {
        case .warmup:
            spots = [.on, .under]
            asks = [.on, .under]
        case .normal:
            spots = [.on, .under, side]
            asks = [.on, .under, .nextTo]
        case .harder:
            spots = [.on, .under, side]
            asks = [.under, .nextTo, .nextTo]
        case .challenge where age >= 5:
            spots = [.left, .right, Bool.random() ? .on : .under]
            asks = [.left, .right]
        case .challenge:
            spots = [.on, .under, side]
            asks = [.on, .under, .nextTo]
        }
        let animals = Array(tableAnimals.shuffled().prefix(spots.count))
        let ask = asks.randomElement()!
        let target: TableSpot
        let prompt: String
        switch ask {
        case .on:
            target = .on
            prompt = L.t("Who is on the table?", no: "Hvem er på bordet?",
                         es: "¿Quién está encima de la mesa?", pt: "Quem está em cima da mesa?")
        case .under:
            target = .under
            prompt = L.t("Who is under the table?", no: "Hvem er under bordet?",
                         es: "¿Quién está debajo de la mesa?", pt: "Quem está debaixo da mesa?")
        case .nextTo:
            target = side
            prompt = L.t("Who is next to the table?", no: "Hvem er ved siden av bordet?",
                         es: "¿Quién está al lado de la mesa?", pt: "Quem está ao lado da mesa?")
        case .left:
            target = .left
            prompt = L.t("Who is on the left of the table?", no: "Hvem er til venstre for bordet?",
                         es: "¿Quién está a la izquierda de la mesa?", pt: "Quem está à esquerda da mesa?")
        case .right:
            target = .right
            prompt = L.t("Who is on the right of the table?", no: "Hvem er til høyre for bordet?",
                         es: "¿Quién está a la derecha de la mesa?", pt: "Quem está à direita da mesa?")
        }
        let index = spots.firstIndex(of: target)!
        return Exercise(
            game: GameSpec(kind: .position, prompt: prompt, answerText: animals[index],
                           payload: PositionPayload(animals: animals, spots: spots)),
            correctAnswer: index + 1,
            options: Array(1...spots.count).shuffled(),
            difficulty: difficulty
        )
    }
}

/// A drawn table standing on the floor, with the animals on it, under it and beside it.
struct PositionGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: PositionPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    // Drawn on a 290 × 180 grid, scaled up on iPad.
    private var s: CGFloat { expanded ? 1.7 : iPadScale.factor }

    var body: some View {
        VStack(spacing: expanded ? 36 : 24) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                ZStack {
                    block(x: 145, y: 177.5, width: 290, height: 2, color: GameStyle.hairline, border: false)
                    block(x: 92, y: 136, width: 14, height: 80, color: GeniColor.orange)
                    block(x: 198, y: 136, width: 14, height: 80, color: GeniColor.orange)
                    block(x: 145, y: 90, width: 150, height: 18, color: GeniColor.orange)
                    ForEach(Array(payload.animals.enumerated()), id: \.offset) { index, animal in
                        let spot = center(of: payload.spots[index])
                        Text(animal)
                            .font(.system(size: 48 * s))
                            .frame(width: 60 * s, height: 60 * s)
                            .position(x: spot.x * s, y: spot.y * s)
                            .accessibilityLabel(description(of: animal, at: payload.spots[index]))
                    }
                }
                .frame(width: 290 * s, height: 180 * s)
                .accessibilityElement(children: .contain)
                .allowsHitTesting(false)
            }
            GameChoices(choices: exercise.options.map { GameChoice(label: payload.animals[$0 - 1], value: $0) },
                        exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }

    private func description(of animal: String, at spot: TableSpot) -> String {
        switch spot {
        case .on:
            return L.t("\(animal) on the table", no: "\(animal) på bordet",
                       es: "\(animal) encima de la mesa", pt: "\(animal) em cima da mesa")
        case .under:
            return L.t("\(animal) under the table", no: "\(animal) under bordet",
                       es: "\(animal) debajo de la mesa", pt: "\(animal) debaixo da mesa")
        case .left:
            return L.t("\(animal) to the left of the table", no: "\(animal) til venstre for bordet",
                       es: "\(animal) a la izquierda de la mesa", pt: "\(animal) à esquerda da mesa")
        case .right:
            return L.t("\(animal) to the right of the table", no: "\(animal) til høyre for bordet",
                       es: "\(animal) a la derecha de la mesa", pt: "\(animal) à direita da mesa")
        }
    }

    private func center(of spot: TableSpot) -> CGPoint {
        switch spot {
        case .on: return CGPoint(x: 145, y: 47)
        case .under: return CGPoint(x: 145, y: 139)
        case .left: return CGPoint(x: 38, y: 142)
        case .right: return CGPoint(x: 252, y: 142)
        }
    }

    private func block(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color, border: Bool = true) -> some View {
        RoundedRectangle(cornerRadius: border ? 4 * s : 0)
            .fill(color)
            .overlay(RoundedRectangle(cornerRadius: 4 * s).stroke(GameStyle.hairline, lineWidth: border ? 1.5 : 0))
            .frame(width: width * s, height: height * s)
            .position(x: x * s, y: y * s)
            .accessibilityHidden(true)
    }
}
