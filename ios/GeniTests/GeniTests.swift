//
//  GeniTests.swift
//  GeniTests
//
//  Created by Rork on March 21, 2026.
//

import Testing
@testable import Geni

struct GeniTests {

    @Test func bigVisualArithmeticFallsBackToEquationOnly() async throws {
        let bigAddition = Exercise(
            emojiFormat: .visualAddition,
            emojiSymbol: "🍎",
            count: 72,
            count2: 23,
            difficulty: .challenge
        )

        #expect(bigAddition.shouldShowEmojiCounting == false)
        #expect(bigAddition.prompt == "72 + 23 = ?")

        let bigSubtraction = Exercise(
            middleFormat: .visualSubtraction,
            op1: 72,
            op2: 23,
            operation: .subtraction,
            difficulty: .challenge,
            emoji: "🍎"
        )

        #expect(bigSubtraction.shouldShowEmojiCounting == false)
        #expect(bigSubtraction.prompt == "72 − 23 = ?")
    }

    @Test func visualSubtractionGeneratorStaysWithinEmojiCap() async throws {
        for difficulty in [ExerciseDifficulty.warmup, .normal, .harder, .challenge] {
            for _ in 0..<50 {
                let exercise = await MainActor.run {
                    ExerciseGenerator.generateVisualSubtractionExercise(
                        difficulty: difficulty,
                        ageGroup: .older
                    )
                }

                #expect(exercise.operand1 <= Exercise.maxCountableEmojis)
                #expect(exercise.operand2 < exercise.operand1)
                #expect(exercise.shouldShowEmojiCounting)
            }
        }
    }

    @Test func comparisonExercisesAlwaysShowDifferentResults() async throws {
        for operation in [MathOperation.addition, .subtraction, .multiplication, .division] {
            for _ in 0..<100 {
                let exercise = Exercise(
                    operand1: 10,
                    operand2: 2,
                    operation: operation,
                    difficulty: .normal,
                    format: .comparison
                )

                let left = try #require(exercise.comparisonLeft)
                let right = try #require(exercise.comparisonRight)

                #expect(evaluate(left) != evaluate(right))
            }
        }
    }

    @Test func matchConnectExercisesAlwaysHaveValidUniquePairs() async throws {
        let ageGroups: [AgeGroup] = [.young, .middle, .older]
        let operationSets = MathOperation.allCases.map { [$0] } + [MathOperation.allCases]
        let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

        for difficulty in difficulties {
            for ageGroup in ageGroups {
                for operations in operationSets {
                    for _ in 0..<100 {
                        let exercise = await MainActor.run {
                            ExerciseGenerator.generateMatchConnectExercise(
                                difficulty: difficulty,
                                ageGroup: ageGroup,
                                ops: operations
                            )
                        }

                        let leftLabels = try #require(exercise.matchLeftLabels)
                        let rightLabels = try #require(exercise.matchRightLabels)
                        let correctIndices = try #require(exercise.correctMatchIndices)

                        #expect(leftLabels.count == rightLabels.count)
                        #expect(leftLabels.count == correctIndices.count)
                        #expect(Set(rightLabels).count == rightLabels.count)

                        for leftIndex in leftLabels.indices {
                            let rightIndex = correctIndices[leftIndex]
                            #expect(rightLabels.indices.contains(rightIndex))

                            let expectedAnswer = try #require(Int(rightLabels[rightIndex]))
                            #expect(try evaluateMatchLabel(leftLabels[leftIndex]) == expectedAnswer)
                        }
                    }
                }
            }
        }
    }

    @Test func generatedDailyChaptersAlwaysContainTwentyExercises() async throws {
        let profiles = [
            ChildProfile(nickname: "A", age: 6, avatarId: "lion"),
            ChildProfile(nickname: "B", age: 7, avatarId: "lion"),
            ChildProfile(nickname: "C", age: 9, avatarId: "lion"),
        ]

        for profile in profiles {
            for _ in 0..<100 {
                let chapter = await MainActor.run {
                    ExerciseGenerator.generateChapter(profile: profile)
                }

                #expect(chapter.count == 20)
            }
        }
    }

    @Test func generatedTopicChaptersAlwaysContainTwentyExercises() async throws {
        let profiles = [
            ChildProfile(nickname: "B", age: 7, avatarId: "lion"),
            ChildProfile(nickname: "C", age: 9, avatarId: "lion"),
        ]
        let topics: [MathTopic] = [.strategies, .timeAndCalendar, .logicPatterns]

        for profile in profiles {
            for topic in topics {
                for _ in 0..<100 {
                    let chapter = await MainActor.run {
                        ExerciseGenerator.generateTopicChapter(profile: profile, topic: topic)
                    }

                    #expect(chapter.count == 20)
                }
            }
        }
    }

    @Test func speechRecognitionContinuesWithinSameUtteranceAfterInitialProgress() async throws {
        let count = await MainActor.run {
            let service = SpeechRecognitionService()
            service.recognizedWords = ["visste", "du", "at", "blekkspruter"]

            return service.matchedWordCount(
                expected: ["visste", "du", "at", "blekkspruter", "er"],
                startFrom: 3
            )
        }

        #expect(count == 4)
    }

    @Test func speechRecognitionCanAdvanceAfterRecognizerRestart() async throws {
        let count = await MainActor.run {
            let service = SpeechRecognitionService()
            service.recognizedWords = ["blekkspruter"]

            return service.matchedWordCount(
                expected: ["visste", "du", "at", "blekkspruter", "er"],
                startFrom: 3
            )
        }

        #expect(count == 4)
    }

    @Test func listenModeProgressFollowsMatchedWords() async throws {
        let progress = await MainActor.run {
            let text = ReadingText(
                id: "test",
                titleEN: "Test",
                titleNO: "Test",
                titleES: "Test",
                titlePT: "Test",
                contentEN: "one two three four",
                contentNO: "en to tre fire",
                contentES: "uno dos tres cuatro",
                contentPT: "um dois tres quatro",
                ageGroup: .young
            )
            let profile = ChildProfile(nickname: "A", age: 6, avatarId: "lion")
            let vm = ReadingViewModel(profile: profile, readingText: text, mode: .listenToMeRead, date: "2026-04-18")
            vm.matchedWordCount = 2

            return vm.progress
        }

        #expect(progress == 0.5)
    }

    private func evaluate(_ expression: (Int, MathOperation, Int)) -> Int {
        switch expression.1 {
        case .addition:
            expression.0 + expression.2
        case .subtraction:
            expression.0 - expression.2
        case .multiplication:
            expression.0 * expression.2
        case .division:
            expression.0 / expression.2
        }
    }

    private func evaluateMatchLabel(_ label: String) throws -> Int {
        let parts = label.split(separator: " ")
        #expect(parts.count == 3)

        let lhs = try #require(Int(String(parts[0])))
        let rhs = try #require(Int(String(parts[2])))

        switch String(parts[1]) {
        case "+":
            return lhs + rhs
        case "−":
            return lhs - rhs
        case "×":
            return lhs * rhs
        case "÷":
            return lhs / rhs
        default:
            throw MatchLabelError.unsupportedOperator(String(parts[1]))
        }
    }

    private enum MatchLabelError: Error {
        case unsupportedOperator(String)
    }

}
