import Foundation
import Testing
@testable import Geni

@MainActor
struct ProfileAndMathTests {

    // MARK: - Age-5 operation spotlight

    @Test func ageFiveSpotlightUsesSelectedOperation() {
        let profile = ChildProfile(nickname: "Mini", age: 5, avatarId: "lion")

        for op in MathOperation.allCases {
            for _ in 0..<25 {
                let chapter = ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: op)
                #expect(chapter.count == 20)
                for exercise in chapter {
                    #expect(exercise.operation == op)
                    #expect(exercise.correctAnswer >= 0)
                    #expect(exercise.operand1 <= 10 && exercise.operand2 <= 10)
                }
            }
        }
    }

    @Test func ageFiveSpotlightKeepsAnswersExactAndSmall() {
        let profile = ChildProfile(nickname: "Mini", age: 5, avatarId: "lion")

        for _ in 0..<50 {
            for exercise in ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: .subtraction) {
                #expect(exercise.operand1 >= exercise.operand2)
                #expect(exercise.correctAnswer == exercise.operand1 - exercise.operand2)
            }
            for exercise in ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: .multiplication) {
                #expect(exercise.correctAnswer == exercise.operand1 * exercise.operand2)
                #expect(exercise.correctAnswer <= 16)
            }
            for exercise in ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: .division) {
                #expect(exercise.operand2 > 0)
                #expect(exercise.operand1 % exercise.operand2 == 0)
                #expect(exercise.correctAnswer == exercise.operand1 / exercise.operand2)
            }
        }
    }

    // MARK: - Matching attempts

    private func makeMatchViewModel(persistence: PersistenceService) -> ChapterViewModel {
        let profile = ChildProfile(nickname: "Matcher", age: 7, avatarId: "lion")
        let exercise = Exercise(
            matchLeft: ["1 + 1", "2 + 2"],
            matchRight: ["2", "4"],
            correctIndices: [0, 1],
            difficulty: .normal
        )
        let chapter = ChapterProgress(childId: profile.id, date: "2026-01-01")
        return ChapterViewModel(profile: profile, chapter: chapter, exercises: [exercise])
    }

    @Test func matchingWithoutMistakesIsFirstTry() {
        let persistence = PersistenceService()
        let vm = makeMatchViewModel(persistence: persistence)
        defer { UserDefaults.standard.removeObject(forKey: "geni_chapters_" + vm.profile.id) }

        vm.submitMatch(leftIndex: 0, rightIndex: 0, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 1, rightIndex: 1, pathPoints: [], persistence: persistence)

        let result = vm.chapter.exerciseResults.first
        #expect(vm.chapter.exerciseResults.count == 1)
        #expect(result?.firstAttemptCorrect == true)
        #expect(result?.attemptsUsed == 1)
    }

    @Test func matchingMistakesAreCounted() {
        let persistence = PersistenceService()
        let vm = makeMatchViewModel(persistence: persistence)
        defer { UserDefaults.standard.removeObject(forKey: "geni_chapters_" + vm.profile.id) }

        vm.submitMatch(leftIndex: 0, rightIndex: 1, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 0, rightIndex: 0, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 1, rightIndex: 1, pathPoints: [], persistence: persistence)

        let result = vm.chapter.exerciseResults.first
        #expect(vm.wrongMatchCount == 1)
        #expect(result?.firstAttemptCorrect == false)
        #expect(result?.attemptsUsed == 2)
        #expect(result?.wasCorrect == true)
    }

    @Test func matchingWithManyMistakesIsNotCorrect() {
        let persistence = PersistenceService()
        let vm = makeMatchViewModel(persistence: persistence)
        defer { UserDefaults.standard.removeObject(forKey: "geni_chapters_" + vm.profile.id) }

        vm.submitMatch(leftIndex: 0, rightIndex: 1, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 1, rightIndex: 0, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 0, rightIndex: 0, pathPoints: [], persistence: persistence)
        vm.submitMatch(leftIndex: 1, rightIndex: 1, pathPoints: [], persistence: persistence)

        let result = vm.chapter.exerciseResults.first
        #expect(result?.attemptsUsed == 3)
        #expect(result?.firstAttemptCorrect == false)
        #expect(result?.wasCorrect == false)
    }

    // MARK: - Completion fires once

    @Test func chapterCompletionIsClaimedOnce() {
        let profile = ChildProfile(nickname: "Timer", age: 7, avatarId: "lion")
        let chapter = ChapterProgress(childId: profile.id, date: "2026-01-01", chapterType: .timeAttack)
        let vm = ChapterViewModel(profile: profile, chapter: chapter, exercises: [])

        #expect(vm.claimCompletion() == true)
        #expect(vm.claimCompletion() == false)
        #expect(vm.hasCompleted)
        #expect(vm.timerTask == nil)
    }
}
