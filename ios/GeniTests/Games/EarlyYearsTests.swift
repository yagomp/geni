import Foundation
import Testing
@testable import Geni

/// Ordinal, position, finger numbers and big/small for ages 4–5.
@MainActor
@Suite(.serialized)
struct EarlyYearsTests {
    private let kinds: [GameKind] = [.ordinal, .position, .fingerNumbers, .bigSmall]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    private func eachExercise(_ kinds: [GameKind]? = nil, _ check: (GameKind, Int, ExerciseDifficulty, Exercise) -> Void) {
        for kind in kinds ?? self.kinds {
            for age in kind.ages {
                for difficulty in difficulties {
                    for _ in 0..<100 {
                        check(kind, age, difficulty, EarlyYearsGames.make(kind, age: age, difficulty: difficulty))
                    }
                }
            }
        }
    }

    @Test func everyGameIsAWellFormedPictureGame() {
        eachExercise { kind, age, difficulty, exercise in
            #expect(exercise.format == .game)
            #expect(exercise.difficulty == difficulty)
            guard let game = exercise.game else { Issue.record("no game for \(kind)"); return }
            #expect(game.kind == kind)
            #expect(!game.prompt.isEmpty)
            #expect(!game.answerText.isEmpty)
            #expect((2...4).contains(exercise.options.count))
            #expect(Set(exercise.options).count == exercise.options.count)
            #expect(exercise.options.contains(exercise.correctAnswer))
            for symbol in ["+", "=", "−", "-", "×", "÷"] {
                #expect(!game.prompt.contains(symbol), "\(kind) age \(age): \(game.prompt)")
            }
        }
    }

    @Test func ordinalPointsAtTheRightAnimal() {
        eachExercise([.ordinal]) { _, age, difficulty, exercise in
            guard let spec = exercise.game, let payload = spec.payload as? OrdinalPayload else {
                Issue.record("ordinal payload missing"); return
            }
            let count = payload.animals.count
            #expect((3...4).contains(count))
            #expect(Set(payload.animals).count == count)
            #expect(payload.animals.allSatisfy(EarlyYearsGames.queueAnimals.contains))
            #expect(exercise.options.sorted() == Array(1...count))
            #expect(spec.answerText == payload.animals[exercise.correctAnswer - 1])
            if difficulty == .warmup { #expect(count == 3) }
            if difficulty == .warmup || difficulty == .normal {
                #expect(exercise.correctAnswer == 1 || exercise.correctAnswer == count)
            }
        }
    }

    @Test func ordinalAnswersMatchTheQuestion() {
        L.withEachLanguage { language in
            guard language == .english else { return }
            eachExercise([.ordinal]) { _, _, _, exercise in
                guard let spec = exercise.game, let payload = spec.payload as? OrdinalPayload else { return }
                let count = payload.animals.count
                let expected: Int? = switch spec.prompt {
                case "Who is first?": 1
                case "Who is second?": 2
                case "Who is third?": 3
                case "Who is last?": count
                case "Who is in the middle?": count == 3 ? 2 : nil
                default: nil
                }
                #expect(expected == exercise.correctAnswer, "\(spec.prompt) in a queue of \(count)")
            }
        }
    }

    @Test func positionHasOneAnimalPerSpotAndTheRightOneIsAsked() {
        L.withEachLanguage { language in
            guard language == .english else { return }
            eachExercise([.position]) { _, age, difficulty, exercise in
                guard let spec = exercise.game, let payload = spec.payload as? PositionPayload else {
                    Issue.record("position payload missing"); return
                }
                #expect(payload.animals.count == payload.spots.count)
                #expect(Set(payload.animals).count == payload.animals.count)
                #expect(Set(payload.spots).count == payload.spots.count)
                // "Next to" only works with exactly one animal beside the table.
                #expect(payload.spots.filter { $0 == .left || $0 == .right }.count <= (difficulty == .challenge && age >= 5 ? 2 : 1))
                let spot = payload.spots[exercise.correctAnswer - 1]
                #expect(spec.answerText == payload.animals[exercise.correctAnswer - 1])
                switch spec.prompt {
                case "Who is on the table?": #expect(spot == .on)
                case "Who is under the table?": #expect(spot == .under)
                case "Who is next to the table?": #expect(spot == .left || spot == .right)
                case "Who is on the left of the table?": #expect(spot == .left && age >= 5 && difficulty == .challenge)
                case "Who is on the right of the table?": #expect(spot == .right && age >= 5 && difficulty == .challenge)
                default: Issue.record("unexpected prompt \(spec.prompt)")
                }
            }
        }
    }

    @Test func fingerNumbersStayInRangeAndChoicesAreCountable() {
        eachExercise([.fingerNumbers]) { _, age, difficulty, exercise in
            guard let spec = exercise.game, let payload = spec.payload as? FingerPayload else {
                Issue.record("finger payload missing"); return
            }
            let maximum = age >= 5 && (difficulty == .harder || difficulty == .challenge) ? 10 : 5
            #expect(payload.count == exercise.correctAnswer)
            #expect((1...maximum).contains(payload.count))
            #expect(payload.choices == exercise.options)
            #expect(payload.choices.allSatisfy { (1...maximum).contains($0) })
            if age == 4 && difficulty == .warmup { #expect(payload.count <= 3) }
            if let object = payload.object {
                // Object tiles only for one hand, so every tile is easy to count.
                #expect(payload.choices.allSatisfy { $0 <= 5 })
                #expect(spec.answerText == String(repeating: object, count: payload.count))
            } else {
                #expect(spec.answerText == "\(payload.count)")
            }
        }
    }

    @Test func bigSmallHasOneClearWinner() {
        eachExercise([.bigSmall]) { _, _, difficulty, exercise in
            guard let spec = exercise.game, let payload = spec.payload as? BigSmallPayload else {
                Issue.record("bigSmall payload missing"); return
            }
            #expect(payload.sizes.count == (difficulty == .warmup ? 2 : 3))
            #expect(exercise.options == Array(1...payload.sizes.count))
            let sorted = payload.sizes.sorted()
            for (small, big) in zip(sorted, sorted.dropFirst()) {
                #expect(big / small >= 1.4)
            }
            let picked = payload.sizes[exercise.correctAnswer - 1]
            #expect(picked == sorted.first || picked == sorted.last)
            if difficulty == .warmup || difficulty == .normal { #expect(payload.item != nil) }
        }
    }

    @Test func bigSmallAnswerMatchesTheQuestion() {
        L.withEachLanguage { language in
            guard language == .english else { return }
            eachExercise([.bigSmall]) { _, _, _, exercise in
                guard let spec = exercise.game, let payload = spec.payload as? BigSmallPayload else { return }
                let picked = payload.sizes[exercise.correctAnswer - 1]
                switch spec.prompt {
                case "Which one is the biggest?", "Which snake is the longest?":
                    #expect(picked == payload.sizes.max())
                case "Which one is the smallest?", "Which snake is the shortest?":
                    #expect(picked == payload.sizes.min())
                default:
                    Issue.record("unexpected prompt \(spec.prompt)")
                }
                #expect(spec.prompt.contains("snake") == (payload.item == nil))
            }
        }
    }

    @Test func everyLanguageHasText() {
        L.withEachLanguage { language in
            var prompts = Set<String>()
            eachExercise { kind, _, _, exercise in
                let prompt = exercise.game?.prompt ?? ""
                #expect(!prompt.isEmpty, "\(kind) in \(language)")
                prompts.insert(prompt)
            }
            // first, second, third, middle, last; on, under, next to, left, right; fingers; 4 size questions
            #expect(prompts.count == 15, "\(language): \(prompts.sorted())")
        }
    }

    @Test func choicesAreInMixedPositions() {
        var firstIsCorrect = 0
        var total = 0
        eachExercise([.fingerNumbers]) { _, _, _, exercise in
            total += 1
            if exercise.options.first == exercise.correctAnswer { firstIsCorrect += 1 }
        }
        #expect(firstIsCorrect < total / 2)
    }
}

private extension L {
    /// Runs `body` once per app language and restores the child's language afterwards.
    @MainActor static func withEachLanguage(_ body: (AppLanguage) -> Void) {
        let saved = UserDefaults.standard.string(forKey: "geni_app_language")
        defer { UserDefaults.standard.set(saved, forKey: "geni_app_language") }
        for language in AppLanguage.allCases {
            selectedLanguage = language
            body(language)
        }
    }
}
