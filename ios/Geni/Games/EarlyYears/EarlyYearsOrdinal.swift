import SwiftUI

/// A queue of animals walking to a house. `animals[0]` stands at the door; answer tile i has value i + 1.
nonisolated struct OrdinalPayload: GamePayload {
    let animals: [String]
}

extension EarlyYearsGames {
    /// Apple's full-body animal emoji face left, so the house sits on the left and they walk toward it.
    static let queueAnimals = ["🐕", "🐈", "🐖", "🐄", "🐑", "🐓", "🦆", "🐘", "🐢", "🐁", "🦔", "🐐", "🦒", "🦓", "🐅", "🦛"]

    private enum Place: CaseIterable { case first, second, third, middle, last }

    static func ordinal(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let count: Int
        let asks: [Place]
        switch difficulty {
        case .warmup:
            count = 3
            asks = [.first, .last]
        case .normal:
            count = Int.random(in: 3...4)
            asks = [.first, .last]
        case .harder:
            count = Int.random(in: 3...4)
            asks = count == 3 ? [.middle, .last] : [.second, .first]
        case .challenge:
            count = age >= 5 ? 4 : Int.random(in: 3...4)
            asks = count == 3 ? [.middle] : age >= 5 ? [.second, .third] : [.second, .last]
        }
        let animals = Array(queueAnimals.shuffled().prefix(count))
        let place = asks.randomElement()!
        let index: Int
        let prompt: String
        switch place {
        case .first:
            index = 0
            prompt = L.t("Who is first?", no: "Hvem er først?", es: "¿Quién va primero?", pt: "Quem vai em primeiro?")
        case .second:
            index = 1
            prompt = L.t("Who is second?", no: "Hvem er nummer to?", es: "¿Quién va segundo?", pt: "Quem vai em segundo?")
        case .third:
            index = 2
            prompt = L.t("Who is third?", no: "Hvem er nummer tre?", es: "¿Quién va tercero?", pt: "Quem vai em terceiro?")
        case .middle:
            index = count / 2
            prompt = L.t("Who is in the middle?", no: "Hvem er i midten?", es: "¿Quién va en el medio?", pt: "Quem vai no meio?")
        case .last:
            index = count - 1
            prompt = L.t("Who is last?", no: "Hvem er sist?", es: "¿Quién va el último?", pt: "Quem vai em último?")
        }
        return Exercise(
            game: GameSpec(kind: .ordinal, prompt: prompt, answerText: animals[index],
                           payload: OrdinalPayload(animals: animals)),
            correctAnswer: index + 1,
            options: Array(1...count).shuffled(),
            difficulty: difficulty
        )
    }
}

/// The house on the left and an arrow under the queue make its direction explicit.
struct OrdinalGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: OrdinalPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    private var size: CGFloat { expanded ? 84 : iPadScale.value(54) }

    var body: some View {
        VStack(spacing: expanded ? 36 : 24) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: expanded ? 10 : 4) {
                        Text("🏠")
                            .font(.system(size: size * 1.25))
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                        ForEach(Array(payload.animals.enumerated()), id: \.offset) { _, animal in
                            Text(animal)
                                .font(.system(size: size))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, minHeight: size * 1.3)
                        }
                    }
                    // A bold arrow pointing to the house: the front of the queue is next to it
                    HStack(spacing: 0) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: expanded ? 30 : 20, weight: .black))
                        GeniShape(scale: 0.25).frame(height: expanded ? 8 : 6)
                    }
                    .foregroundStyle(GeniColor.orange)
                    .padding(.leading, size * 0.9)
                    .padding(.trailing, size * 0.3)
                    .padding(.top, 6)
                }
                .padding(.top, 12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L.t("Animals going to the house, from first to last: \(payload.animals.joined(separator: ", "))",
                                        no: "Dyrene på vei til huset, fra først til sist: \(payload.animals.joined(separator: ", "))",
                                        es: "Animales que van a la casa, del primero al último: \(payload.animals.joined(separator: ", "))",
                                        pt: "Animais a caminho da casa, do primeiro ao último: \(payload.animals.joined(separator: ", "))"))
                .allowsHitTesting(false)
            }
            GameChoices(choices: exercise.options.map { GameChoice(label: payload.animals[$0 - 1], value: $0) },
                        exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }
}
