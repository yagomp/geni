import Foundation
import Testing
@testable import Geni

/// Shape games (ages 4–6): finish the pattern, find the shape, spot the odd one out.
@Suite(.serialized)
@MainActor
struct ShapeTests {
    private let kinds: [GameKind] = [.patternNext, .shapeFind, .oddOneOut]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    private func samples(_ kind: GameKind) -> [(age: Int, difficulty: ExerciseDifficulty, exercise: Exercise)] {
        var all: [(age: Int, difficulty: ExerciseDifficulty, exercise: Exercise)] = []
        for age in kind.ages {
            for difficulty in difficulties {
                for _ in 0..<100 {
                    all.append((age, difficulty, ShapeGames.make(kind, age: age, difficulty: difficulty)))
                }
            }
        }
        return all
    }

    /// Checks every game: right format and kind, one-line prompt, distinct options, answer among them.
    private func checkCommon(_ kind: GameKind, _ sample: (age: Int, difficulty: ExerciseDifficulty, exercise: Exercise)) -> ChoicePayload? {
        let exercise = sample.exercise
        #expect(exercise.format == .game)
        #expect(exercise.game?.kind == kind)
        #expect(exercise.difficulty == sample.difficulty)
        let prompt = exercise.game?.prompt ?? ""
        #expect(!prompt.isEmpty)
        #expect(!prompt.contains("\n"))
        #expect(exercise.game?.answerText.isEmpty == false)
        #expect((2...4).contains(exercise.options.count))
        #expect(Set(exercise.options).count == exercise.options.count)
        #expect(exercise.options.contains(exercise.correctAnswer))
        if sample.age <= 5 {
            for symbol in ["+", "=", "−", "×", "÷"] {
                #expect(!prompt.contains(symbol))
            }
        }
        guard let payload = exercise.game?.payload as? ChoicePayload else {
            Issue.record("\(kind) should be a pick-one choice game")
            return nil
        }
        #expect(Set(payload.choices.map(\.value)) == Set(exercise.options))
        #expect(Set(payload.choices.map(\.label)).count == payload.choices.count)
        let correct = payload.choices.first { $0.value == exercise.correctAnswer }
        #expect(correct?.label == exercise.game?.answerText)
        return payload
    }

    @Test func samplesCoverEveryAgeAndDifficulty() {
        for kind in kinds {
            #expect(!kind.ages.isEmpty)
            #expect(samples(kind).count == kind.ages.count * difficulties.count * 100)
        }
    }

    @Test func everyLanguageProducesText() {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for kind in kinds {
                for age in kind.ages {
                    let exercise = ShapeGames.make(kind, age: age, difficulty: .normal)
                    #expect(exercise.game?.prompt.isEmpty == false)
                    #expect(exercise.game?.answerText.isEmpty == false)
                }
            }
        }
    }

    @Test func patternNextShowsAPatternWithTheNextPictureMissing() {
        for sample in samples(.patternNext) {
            guard let payload = checkCommon(.patternNext, sample), payload.scene.count == 1 else { continue }
            let row = payload.scene[0]
            #expect(row.last == "❓")
            let shown = Array(row.dropLast())
            #expect((3...5).contains(shown.count))
            #expect(payload.choices.count == 3)

            // Age 4 alternates AB, 5 repeats ABB or AAB, 6 runs ABC.
            let period = sample.age <= 4 ? 2 : 3
            let letters = sample.age == 6 ? 3 : 2
            #expect(Set(shown).count == letters)
            #expect(shown.indices.dropFirst(period).allSatisfy { shown[$0] == shown[$0 - period] })

            // The answer is the picture one period back, and every shown picture is one of the three choices.
            #expect(payload.choices.first { $0.value == sample.exercise.correctAnswer }?.label == shown[shown.count - period])
            #expect(Set(shown).isSubset(of: Set(payload.choices.map(\.label))))
        }
    }

    @Test func shapeFindAsksForOneShapeAndShowsEachShapeOnce() {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        L.selectedLanguage = .english
        let words: [ShapeGames.Figure: String] = [.circle: "circle", .square: "square", .triangle: "triangle", .star: "star"]
        for sample in samples(.shapeFind) {
            guard let payload = checkCommon(.shapeFind, sample) else { continue }
            #expect(payload.scene.isEmpty)
            #expect(payload.choices.count == 4)

            // One picture of each shape, so there is exactly one right answer and never two squares.
            let figures = payload.choices.map { ShapeGames.figure(of: $0.label) }
            #expect(figures.allSatisfy { $0 != nil })
            #expect(Set(figures.compactMap { $0 }).count == 4)

            guard let correct = payload.choices.first(where: { $0.value == sample.exercise.correctAnswer }),
                  let asked = ShapeGames.figure(of: correct.label) else {
                Issue.record("the right answer should be a known shape")
                continue
            }
            #expect(sample.age >= 5 || asked != .star)
            #expect(sample.exercise.game?.prompt == "Find the \(words[asked] ?? "")")
            #expect(payload.choices.filter { ShapeGames.figure(of: $0.label) == asked }.count == 1)

            // Harder: the square and circle share a colour, so only the shape tells them apart.
            if sample.difficulty.rawValue >= ExerciseDifficulty.harder.rawValue {
                let circle = payload.choices.first { ShapeGames.figure(of: $0.label) == .circle }?.label ?? ""
                let square = payload.choices.first { ShapeGames.figure(of: $0.label) == .square }?.label ?? ""
                #expect(ShapeGames.colourPairs.contains { $0.circle == circle && $0.square == square })
            }
        }
    }

    @Test func oddOneOutHasThreeFromOneGroupAndOneOther() {
        for sample in samples(.oddOneOut) {
            guard let payload = checkCommon(.oddOneOut, sample), payload.choices.count == 4 else { continue }
            #expect(payload.scene.isEmpty)
            guard let correct = payload.choices.first(where: { $0.value == sample.exercise.correctAnswer }) else { continue }
            let others = payload.choices.filter { $0 != correct }
            guard others.count == 3 else { continue }

            // Some group holds all three others and not the odd one out.
            let shared = others.dropFirst().reduce(ShapeGames.groupNames(of: others[0].label)) {
                $0.intersection(ShapeGames.groupNames(of: $1.label))
            }
            #expect(!shared.subtracting(ShapeGames.groupNames(of: correct.label)).isEmpty)

            // Harder squares-and-circle: the odd circle's colour is one of the squares.
            let squaresAndCircle = others.allSatisfy { ShapeGames.groupNames(of: $0.label).contains("square") }
            if sample.difficulty.rawValue >= ExerciseDifficulty.harder.rawValue, squaresAndCircle,
               let pair = ShapeGames.colourPairs.first(where: { $0.circle == correct.label }) {
                #expect(others.contains { $0.label == pair.square })
            }
        }
    }
}
