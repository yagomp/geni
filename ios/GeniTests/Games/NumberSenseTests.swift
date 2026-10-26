import Foundation
import Testing
@testable import Geni

@MainActor
@Suite(.serialized)
struct NumberSenseTests {
    private let kinds: [GameKind] = [.tenFriends, .doubles, .numberNeighbours, .countBackwards, .skipCounting]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    private func withLanguage(_ language: AppLanguage, _ body: () -> Void) {
        let key = "geni_app_language"
        let saved = UserDefaults.standard.string(forKey: key)
        L.selectedLanguage = language
        body()
        if let saved {
            UserDefaults.standard.set(saved, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Every kind × age × difficulty, ~100 each.
    private func forEachExercise(_ body: (GameKind, Int, ExerciseDifficulty, Exercise) -> Void) {
        for kind in kinds {
            for age in kind.ages {
                for difficulty in difficulties {
                    for _ in 0..<100 {
                        body(kind, age, difficulty, NumberSenseGames.make(kind, age: age, difficulty: difficulty))
                    }
                }
            }
        }
    }

    private func choices(of exercise: Exercise) -> [GameChoice] {
        switch exercise.game?.payload {
        case let p as TenFramePayload: return p.choices
        case let p as DoublesPayload: return p.choices
        case let p as NumberTrackPayload: return p.choices
        case let p as FrogHopPayload: return p.choices
        default: return []
        }
    }

    @Test func everyGameIsWellFormed() {
        forEachExercise { kind, age, difficulty, exercise in
            let tag = "\(kind) age \(age) \(difficulty)"
            #expect(exercise.format == .game, "\(tag)")
            #expect(exercise.game?.kind == kind, "\(tag)")
            #expect(exercise.game?.prompt.isEmpty == false, "\(tag)")
            #expect(exercise.game?.answerText == "\(exercise.correctAnswer)", "\(tag)")
            let tiles = choices(of: exercise)
            #expect(tiles.map(\.value) == exercise.options, "\(tag)")
            #expect((2...4).contains(exercise.options.count), "\(tag)")
            #expect(Set(exercise.options).count == exercise.options.count, "\(tag)")
            #expect(exercise.options.contains(exercise.correctAnswer), "\(tag)")
            #expect(tiles.allSatisfy { $0.label == "\($0.value)" }, "\(tag)")
            if age <= 5 {
                let prompt = exercise.game?.prompt ?? ""
                #expect(!["+", "=", "−", "×", "÷"].contains { prompt.contains($0) }, "\(tag): \(prompt)")
            }
        }
    }

    @Test func numbersStayWithinWhatTheAgeKnows() {
        forEachExercise { kind, age, _, exercise in
            let top: Int = switch kind {
            case .tenFriends: 10
            case .doubles: 20
            case .numberNeighbours: age <= 5 ? 10 : 20
            case .countBackwards: 20
            default: 100
            }
            #expect(exercise.options.allSatisfy { (0...top).contains($0) }, "\(kind) age \(age): \(exercise.options)")
        }
    }

    @Test func tenFriendsMakeTen() {
        forEachExercise { kind, age, difficulty, exercise in
            guard kind == .tenFriends, let p = exercise.game?.payload as? TenFramePayload else { return }
            #expect((1...9).contains(p.filled))
            #expect(p.filled + exercise.correctAnswer == 10)
            #expect(p.showsFrame || !p.equation.isEmpty)
            #expect(NumberSenseGames.frameEmoji.contains(p.emoji))
            if age <= 5 {
                #expect(p.showsFrame && p.equation.isEmpty, "age 5 sees the frame only")
            }
            if age >= 7 && (difficulty == .harder || difficulty == .challenge) {
                #expect(!p.showsFrame, "age 7 harder levels are numbers only")
            }
            if !p.equation.isEmpty {
                #expect(p.equation.contains("?") && p.equation.contains("\(p.filled)") && p.equation.last == "10")
            }
        }
    }

    @Test func doublesAddUp() {
        forEachExercise { kind, age, difficulty, exercise in
            guard kind == .doubles, let p = exercise.game?.payload as? DoublesPayload else { return }
            #expect(p.left + p.right == exercise.correctAnswer)
            #expect((1...10).contains(p.left) && (1...10).contains(p.right))
            if age <= 6 {
                #expect(p.left == p.right && p.left <= 5, "age 6 doubles stay ≤ 5 + 5")
            } else if difficulty == .challenge {
                #expect(abs(p.left - p.right) == 1, "near doubles")
            } else {
                #expect(p.left == p.right)
            }
            if max(p.left, p.right) > 6 {
                #expect(p.picture == .ladybird, "dice and dominoes stop at 6")
            }
        }
    }

    @Test func tracksCountByOne() {
        forEachExercise { kind, age, _, exercise in
            guard let p = exercise.game?.payload as? NumberTrackPayload else { return }
            #expect(p.numbers.filter { $0 == nil }.count == 1)
            let step = kind == .countBackwards ? -1 : 1
            let first = p.numbers[0] ?? (p.numbers[1]! - step)
            let filled = p.numbers.indices.map { first + step * $0 }
            #expect(p.numbers.enumerated().allSatisfy { i, n in n == nil || n == filled[i] }, "\(p.numbers)")
            #expect(filled[p.numbers.firstIndex { $0 == nil }!] == exercise.correctAnswer)
            #expect(p.style == (kind == .countBackwards ? .countdown : .houses))
            let top = kind == .numberNeighbours && age <= 5 ? 10 : 20
            #expect(filled.allSatisfy { (0...top).contains($0) }, "\(filled)")
            if kind == .numberNeighbours {
                #expect(filled.allSatisfy { $0 >= 1 })
            }
        }
    }

    @Test func frogHopsByTheStep() {
        forEachExercise { kind, age, _, exercise in
            guard kind == .skipCounting, let p = exercise.game?.payload as? FrogHopPayload else { return }
            #expect([2, 5, 10].contains(abs(p.step)))
            #expect(p.numbers.count == 5)
            #expect(p.numbers.filter { $0 == nil }.count == 1)
            let first = p.numbers[0] ?? (p.numbers[1]! - p.step)
            let filled = p.numbers.indices.map { first + p.step * $0 }
            #expect(p.numbers.enumerated().allSatisfy { i, n in n == nil || n == filled[i] })
            #expect(filled[p.numbers.firstIndex { $0 == nil }!] == exercise.correctAnswer)
            #expect(filled.allSatisfy { (0...100).contains($0) }, "age \(age): \(filled)")
        }
    }

    @Test func distractorsAreCloseCalls() {
        let tiles = NumberSenseGames.numberChoices(answer: 1, preferred: [0, 2, 9], count: 4, range: 1...10)
        #expect(Set(tiles.map(\.value)) == [1, 2, 9, 3])
        let edge = NumberSenseGames.numberChoices(answer: 10, preferred: [11, 12], count: 3, range: 1...10)
        #expect(Set(edge.map(\.value)) == [10, 9, 8])
    }

    @Test(arguments: AppLanguage.allCases)
    func everyLanguageHasPrompts(language: AppLanguage) {
        withLanguage(language) {
            for kind in kinds {
                for age in kind.ages {
                    for difficulty in difficulties {
                        for _ in 0..<20 {
                            let exercise = NumberSenseGames.make(kind, age: age, difficulty: difficulty)
                            #expect(exercise.game?.prompt.isEmpty == false)
                            #expect(exercise.game?.answerText.isEmpty == false)
                        }
                    }
                }
            }
        }
    }

    @Test func languagesReadDifferently() {
        var prompts = Set<String>()
        for language in AppLanguage.allCases {
            withLanguage(language) {
                prompts.insert(NumberSenseGames.make(.tenFriends, age: 6, difficulty: .normal).game?.prompt ?? "")
            }
        }
        #expect(prompts.count == AppLanguage.allCases.count)
    }
}
