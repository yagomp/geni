import Foundation
import Testing
@testable import Geni

@Suite(.serialized)
@MainActor
struct PlaceValueTests {
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private let kinds: [GameKind] = [.numberLine, .tensOnes]

    @Test func generatedExercisesMeetContractInEveryLanguage() throws {
        let previousLanguage = L.selectedLanguage
        defer { L.selectedLanguage = previousLanguage }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for kind in kinds {
                for age in kind.ages {
                    for difficulty in difficulties {
                        for _ in 0..<100 {
                            let exercise = PlaceValueGames.make(kind, age: age, difficulty: difficulty)
                            let spec = try #require(exercise.game)
                            #expect(exercise.format == .game)
                            #expect(spec.kind == kind)
                            #expect(exercise.difficulty == difficulty)
                            #expect(!spec.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            #expect(!spec.answerText.isEmpty)
                            #expect(spec.answerText == String(exercise.correctAnswer))
                            #expect(Set(exercise.options).count == exercise.options.count)
                            #expect(exercise.options.count <= 4)
                            if !exercise.options.isEmpty {
                                #expect((3...4).contains(exercise.options.count))
                                #expect(exercise.options.contains(exercise.correctAnswer))
                            }
                            if age <= 5 {
                                #expect(!spec.prompt.contains { "+=−×÷".contains($0) })
                            }
                            switch kind {
                            case .numberLine:
                                let payload = try #require(spec.payload as? PlaceValueNumberLinePayload)
                                checkNumberLine(payload, exercise: exercise, age: age, difficulty: difficulty)
                            case .tensOnes:
                                let payload = try #require(spec.payload as? PlaceValueBlocksPayload)
                                checkBlocks(payload, exercise: exercise, difficulty: difficulty)
                            default:
                                Issue.record("Unexpected game kind")
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkNumberLine(_ payload: PlaceValueNumberLinePayload, exercise: Exercise,
                                 age: Int, difficulty: ExerciseDifficulty) {
        let expectedUpper: Int
        switch difficulty {
        case .warmup: expectedUpper = 10
        case .normal: expectedUpper = 20
        case .harder, .challenge: expectedUpper = age == 9 ? 1000 : 100
        }
        #expect(payload.upperBound == expectedUpper)
        #expect(payload.tickStep == (expectedUpper >= 100 ? expectedUpper / 10 : 1))
        #expect(payload.target == exercise.correctAnswer)
        #expect(payload.tickValues.first == 0)
        #expect(payload.tickValues.last == payload.upperBound)
        #expect(payload.tickValues.contains(payload.target))
        #expect((0...1).contains(payload.targetFraction))
        #expect(Int((payload.targetFraction * Double(payload.upperBound)).rounded()) == exercise.correctAnswer)
        #expect(payload.labelledValues.contains(0))
        #expect(payload.labelledValues.contains(payload.upperBound))
        #expect(Set(payload.labelledValues).isSubset(of: Set(payload.tickValues)))
        #expect(payload.choices.map(\.value) == exercise.options)
        #expect(payload.choices.allSatisfy { $0.label == String($0.value) })
        #expect(payload.choices.allSatisfy { payload.tickValues.contains($0.value) })
        #expect(exercise.options.allSatisfy { (0...expectedUpper).contains($0) })
        if difficulty == .warmup {
            #expect(payload.labelledValues == payload.tickValues)
            #expect(payload.choices.count == 3)
        } else {
            #expect(!payload.labelledValues.contains(payload.target))
            #expect(payload.labelledValues.count < payload.tickValues.count)
            #expect(payload.choices.count == 4)
        }
        if difficulty == .harder { #expect(payload.labelledValues == [0, expectedUpper / 2, expectedUpper]) }
        if difficulty == .challenge { #expect(payload.labelledValues == [0, expectedUpper]) }
    }

    private func checkBlocks(_ payload: PlaceValueBlocksPayload, exercise: Exercise, difficulty: ExerciseDifficulty) {
        #expect((1...9).contains(payload.tens))
        #expect((0...9).contains(payload.ones))
        #expect(payload.value == exercise.correctAnswer)
        #expect(payload.tens * 10 + payload.ones == exercise.correctAnswer)
        #expect((10...99).contains(exercise.correctAnswer))
        #expect(payload.choices.map(\.value) == exercise.options)
        #expect(payload.choices.allSatisfy { $0.label == String($0.value) })
        #expect(exercise.options.allSatisfy { (0...99).contains($0) })
        #expect(payload.isBuilding == (difficulty == .harder || difficulty == .challenge))
        if payload.isBuilding {
            #expect(exercise.options.isEmpty)
            #expect(exercise.game?.prompt.contains(String(payload.value)) == true)
            var build = PlaceValueBuildState()
            for _ in 0..<payload.tens { build.addTen() }
            for _ in 0..<payload.ones { build.addOne() }
            #expect(build.value == exercise.correctAnswer)
        } else {
            #expect(!payload.choices.isEmpty)
        }
        if difficulty == .warmup { #expect(exercise.correctAnswer <= 49) }
    }

    @Test func builderCanMakeAndRemoveEveryNumberBelowOneHundred() {
        for number in 0...99 {
            var build = PlaceValueBuildState()
            for _ in 0..<(number / 10) { build.addTen() }
            for _ in 0..<(number % 10) { build.addOne() }
            #expect(build.tens == number / 10)
            #expect(build.ones == number % 10)
            #expect(build.value == number)
            if build.tens > 0 {
                build.removeTen()
                #expect(build.value == number - 10)
                build.addTen()
            }
            if build.ones > 0 {
                build.removeOne()
                #expect(build.value == number - 1)
                build.addOne()
            }
            #expect(build.value == number)
        }
    }

    @Test func builderClampsBothColumnsAndKeepsTheirValuesIndependent() {
        var build = PlaceValueBuildState()
        for _ in 0..<100 {
            build.removeTen()
            build.removeOne()
        }
        #expect(build.value == 0)
        for _ in 0..<100 { build.addOne() }
        #expect(build.ones == 9)
        #expect(build.tens == 0)
        #expect(build.value == 9)
        for _ in 0..<100 { build.addTen() }
        #expect(build.tens == 9)
        #expect(build.ones == 9)
        #expect(build.value == 99)
        for _ in 0..<100 { build.removeTen() }
        #expect(build.tens == 0)
        #expect(build.ones == 9)
        for _ in 0..<100 { build.removeOne() }
        #expect(build.value == 0)
    }

    @Test func choiceOrderVariesAcrossExercises() throws {
        for kind in kinds {
            var correctPositions = Set<Int>()
            for _ in 0..<100 {
                let exercise = PlaceValueGames.make(kind, age: 7, difficulty: .normal)
                correctPositions.insert(try #require(exercise.options.firstIndex(of: exercise.correctAnswer)))
            }
            #expect(correctPositions.count == 4)
        }
    }
}
