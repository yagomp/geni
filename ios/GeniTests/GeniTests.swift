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

}
