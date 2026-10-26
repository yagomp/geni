import Foundation
import Testing
@testable import Geni

@Suite(.serialized)
@MainActor
struct StoryTests {
    private let kinds: [GameKind] = [.timesGroups, .fairShare, .storyMatch]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    @Test func allKindsHaveValidChoicesAcrossAgesDifficultiesAndLanguages() throws {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for kind in kinds {
                for age in kind.ages {
                    for difficulty in difficulties {
                        var answerPositions = Set<Int>()
                        for _ in 0..<100 {
                            let exercise = StoryGames.make(kind, age: age, difficulty: difficulty)
                            let spec = try #require(exercise.game)
                            let payload = try #require(spec.payload as? StoryPayload)
                            #expect(exercise.format == .game)
                            #expect(spec.kind == kind)
                            #expect(exercise.difficulty == difficulty)
                            #expect(!spec.prompt.isEmpty && !spec.answerText.isEmpty)
                            #expect(!spec.prompt.contains("\n"))
                            #expect(spec.prompt.split(whereSeparator: \.isWhitespace).count <= 14)
                            #expect((2...4).contains(exercise.options.count))
                            #expect(Set(exercise.options).count == exercise.options.count)
                            #expect(Set(payload.choices.map(\.label)).count == payload.choices.count)
                            #expect(payload.choices.map(\.value) == exercise.options)
                            #expect(exercise.options.filter { $0 == exercise.correctAnswer }.count == 1)
                            let correct = try #require(payload.choices.first { $0.value == exercise.correctAnswer })
                            #expect(spec.answerText == correct.label)
                            answerPositions.insert(try #require(exercise.options.firstIndex(of: exercise.correctAnswer)))
                            if age <= 5 {
                                #expect(!spec.prompt.contains { "+=−×÷".contains($0) })
                            }
                            try checkMath(exercise, payload: payload, age: age)
                        }
                        #expect(answerPositions.count > 1)
                    }
                }
            }
        }
    }

    private func checkMath(_ exercise: Exercise, payload: StoryPayload, age: Int) throws {
        switch payload.picture {
        case .groups(let picture):
            #expect((2...10).contains(picture.groups))
            #expect((2...6).contains(picture.itemsPerGroup))
            #expect(!picture.item.isEmpty)
            #expect(exercise.operation == .multiplication)
            if exercise.game?.kind == .timesGroups {
                #expect(payload.story == nil)
                #expect(exercise.correctAnswer == picture.groups * picture.itemsPerGroup)
                #expect(exercise.options.allSatisfy { (1...(age == 8 ? 30 : 50)).contains($0) })
                #expect(picture.showsCalculation == (age == 9 && exercise.difficulty.rawValue >= 2))
                if age == 9 && exercise.difficulty == .challenge {
                    #expect((6...10).contains(picture.groups))
                    #expect(picture.itemsPerGroup <= 5)
                } else {
                    #expect(picture.groups <= 5)
                }
            } else {
                let story = try #require(payload.story)
                #expect(picture.groups == story.groups)
                #expect(picture.itemsPerGroup == story.itemsPerGroup)
                #expect(picture.character == story.character)
                #expect(!picture.showsCalculation)
            }
        case .sharing(let picture):
            #expect((2...5).contains(picture.friends))
            #expect((2...8).contains(picture.each))
            #expect((4...44).contains(picture.total))
            #expect(picture.total == picture.each * picture.friends + picture.remainder)
            #expect((0..<picture.friends).contains(picture.remainder))
            #expect(!picture.item.isEmpty)
            #expect(exercise.operation == .division)
            if exercise.game?.kind == .fairShare {
                #expect(payload.story == nil)
                #expect(picture.asksForRemainder == (exercise.difficulty.rawValue >= 2))
                #expect(exercise.correctAnswer == (picture.asksForRemainder ? picture.remainder : picture.each))
                #expect(picture.asksForRemainder ? picture.remainder > 0 : picture.remainder == 0)
                #expect(exercise.options.allSatisfy { (picture.asksForRemainder ? 0...(picture.friends - 1) : 1...10).contains($0) })
            } else {
                let story = try #require(payload.story)
                #expect(picture.total == story.groups * story.itemsPerGroup)
                #expect(picture.friends == story.groups)
                #expect(picture.character == story.character)
                #expect(picture.remainder == 0)
                #expect(!picture.asksForRemainder)
            }
        }
        if exercise.game?.kind == .storyMatch {
            let story = try #require(payload.story)
            #expect((3...5).contains(story.groups))
            #expect((2...6).contains(story.itemsPerGroup))
            #expect(story.operation == .times || story.operation == .share)
            #expect(story.context != .fairyTale || story.groups == 3)
            #expect(exercise.correctAnswer == story.operation.rawValue)
            #expect(exercise.game?.prompt == story.prompt)
            #expect(payload.choices.count == 3)
            for calculation in story.calculations {
                #expect(payload.choices.contains(GameChoice(label: calculation.label, value: calculation.operation.rawValue)))
            }
            let correct = try #require(story.calculations.first { $0.operation == story.operation })
            #expect(correct.left == (story.operation == .times ? story.groups : story.total))
            #expect(correct.right == (story.operation == .times ? story.itemsPerGroup : story.groups))
        }
    }

    @Test func everyLocalizedStoryContextIsShortAndCulturallyNatural() {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for context in StoryContext.allCases {
                for operation in [StoryOperation.times, .share] {
                    let story = StoryProblem(context: context, groups: context == .fairyTale ? 3 : 5,
                                             itemsPerGroup: 6, operation: operation)
                    #expect(!story.prompt.isEmpty)
                    #expect(story.prompt.split(whereSeparator: \.isWhitespace).count <= 14)
                    #expect(!story.prompt.contains { "$€£+×÷−=".contains($0) })
                    if context == .fairyTale {
                        switch language {
                        case .english: #expect(story.prompt.contains("little pigs") && story.character == "🐷")
                        case .norwegian: #expect(story.prompt.contains("Bukkene Bruse") && story.character == "🐐")
                        case .spanish: #expect(story.prompt.contains("tres cerditos") && story.character == "🐷")
                        case .portuguese: #expect(story.prompt.contains("três porquinhos") && story.character == "🐷")
                        }
                    }
                    if context == .sport {
                        switch language {
                        case .english: #expect(story.prompt.contains("football"))
                        case .norwegian: #expect(story.prompt.contains("skiløpere"))
                        case .spanish: #expect(story.prompt.contains("fútbol"))
                        case .portuguese: #expect(story.prompt.contains("futebol"))
                        }
                    }
                    if context == .market {
                        switch language {
                        case .english: #expect(story.prompt.contains("picnic"))
                        case .norwegian: #expect(story.prompt.contains("Kardemomme by"))
                        case .spanish, .portuguese: #expect(story.prompt.contains("mercado"))
                        }
                    }
                }
            }
        }
    }

    @Test func calculationDistractorsDescribeDifferentOperationsAndAnswers() {
        for groups in 3...5 {
            for each in 2...6 {
                for operation in [StoryOperation.times, .share] {
                    let story = StoryProblem(context: .outing, groups: groups, itemsPerGroup: each, operation: operation)
                    let answer = operation == .times ? groups * each : each
                    #expect(Set(story.calculations.map { $0.operation.rawValue }).count == 3)
                    for calculation in story.calculations where calculation.operation != operation {
                        let value: Int
                        switch calculation.operation {
                        case .times: value = calculation.left * calculation.right
                        case .share: value = calculation.left / calculation.right
                        case .add: value = calculation.left + calculation.right
                        case .subtract: value = calculation.left - calculation.right
                        }
                        #expect(value != answer)
                    }
                }
            }
        }
    }
}
