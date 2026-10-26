import Foundation
import Testing
@testable import Geni

/// Language is process-wide. Keep the entire matrix synchronous on the main actor and restore it.
@Suite(.serialized)
@MainActor
struct ChapterFuzzTests {
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private let chapterTypes: [ChapterType] = [.daily, .timeAttack, .perfectRun, .boss, .streak, .operationSpotlight]

    /// Exercise the real result-recording path without JSON encoding or writing millions of answers.
    private final class RecordingPersistence: PersistenceService {
        var lastSaved: ChapterProgress?
        var saveCount = 0

        override func saveChapterProgress(_ progress: ChapterProgress) {
            lastSaved = progress
            saveCount += 1
        }
    }

    private func submittedAnswer(for exercise: Exercise) throws -> Int {
        switch exercise.format {
        case .missingNumber: return exercise.missingNumberCorrectAnswer
        case .trueFalse: return exercise.trueFalseIsCorrect ? 1 : 0
        case .comparison, .compareGroups: return try #require(exercise.options.first)
        case .solveResult, .countingObjects, .visualAddition, .tenFrame,
             .numberBonds, .diceAddition, .visualSubtraction, .evenOddSort,
             .multiStep, .numberSequence, .areaPerimeter, .fractionPick, .longDivision,
             .clockRead, .clockSet, .game, .matchConnect, .clockMatch:
            return exercise.correctAnswer
        }
    }

    private func verify(_ exercises: [Exercise], profile: ChildProfile, type: ChapterType,
                        expectedCount: Int, persistence: RecordingPersistence) throws {
        try #require(exercises.count == expectedCount)
        let chapter = ChapterProgress(childId: profile.id, date: "2026-10-26", chapterType: type)
        let vm = ChapterViewModel(profile: profile, chapter: chapter, exercises: exercises, feedback: .immediate)
        // Time-attack answers run synchronously; don't leave a live timer after each simulation.
        vm.stopTimer()
        let savedBefore = persistence.saveCount

        for (index, exercise) in exercises.enumerated() {
            // Only record failed per-exercise checks: the matrix contains ~2 million exercises.
            guard !exercise.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  vm.currentIndex == index else {
                Issue.record("Empty prompt or wrong index: age \(profile.age), \(type), \(exercise.format), index \(index)")
                return
            }
            let answer = try submittedAnswer(for: exercise)
            switch exercise.format {
            case .matchConnect, .clockMatch:
                let indices = try #require(exercise.correctMatchIndices)
                let left = try #require(exercise.matchLeftLabels)
                let right = try #require(exercise.matchRightLabels)
                try #require(!indices.isEmpty && indices.count == left.count && indices.count == right.count)
                try #require(Set(indices).count == indices.count)
                if exercise.format == .clockMatch {
                    let times = try #require(exercise.clockTimes)
                    try #require(times.count == indices.count)
                    try #require(times.allSatisfy { exercise.options.contains($0.totalMinutes) })
                }
                for (leftIndex, rightIndex) in indices.enumerated() {
                    try #require(right.indices.contains(rightIndex))
                    vm.submitMatch(leftIndex: leftIndex, rightIndex: rightIndex, persistence: persistence)
                }
            case .game where exercise.options.isEmpty:
                vm.submitAnswer(answer, persistence: persistence)
            default:
                guard exercise.options.contains(answer) else {
                    Issue.record("Missing answer \(answer): age \(profile.age), \(type), \(exercise.format), options \(exercise.options)")
                    return
                }
                vm.submitAnswer(answer, persistence: persistence)
                if exercise.format == .evenOddSort {
                    try #require(vm.evenOddStep == 1 && vm.currentIndex == index)
                    vm.submitAnswer(exercise.correctAnswer % 2 == 0 ? 0 : 1, persistence: persistence)
                }
            }
            guard vm.feedbackCorrect, vm.currentIndex == index + 1,
                  vm.chapter.exerciseResults.last?.firstAttemptCorrect == true else {
                Issue.record("Correct submission failed: age \(profile.age), \(type), \(exercise.format), index \(index)")
                return
            }
        }
        try #require(vm.currentExercise == nil && vm.chapter.isComplete)
        try #require(vm.chapter.exerciseResults.count == expectedCount)
        try #require(vm.chapter.firstTryCount == expectedCount)
        try #require(persistence.saveCount - savedBefore == expectedCount)
        try #require(persistence.lastSaved?.id == vm.chapter.id && persistence.lastSaved?.isComplete == true)
        try #require(vm.claimCompletion() && !vm.claimCompletion())
    }

    @Test func everyChapterBuildsAndCompletesAcrossProfilesAndLanguages() throws {
        let originalLanguage = L.selectedLanguage
        defer { L.selectedLanguage = originalLanguage }
        let suite = "geni.chapter-fuzz." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = RecordingPersistence(defaults: defaults)

        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for age in 4...10 {
                for operations in [MathOperation.allCases, [.addition]] {
                    var profile = ChildProfile(nickname: "Fuzz", age: age, avatarId: "lion")
                    profile.operationsEnabled = operations
                    for _ in 0..<100 {
                        for type in chapterTypes {
                            switch type {
                            case .operationSpotlight:
                                for operation in MathOperation.allCases {
                                    try verify(ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: operation),
                                               profile: profile, type: type, expectedCount: profile.dailyExerciseCount,
                                               persistence: persistence)
                                }
                            case .daily, .timeAttack, .perfectRun, .boss, .streak:
                                try verify(ExerciseGenerator.generateChapter(profile: profile, chapterType: type),
                                           profile: profile, type: type, expectedCount: profile.dailyExerciseCount,
                                           persistence: persistence)
                            }
                        }
                        for topic in MathTopic.allCases {
                            try verify(ExerciseGenerator.generateTopicChapter(profile: profile, topic: topic),
                                       profile: profile, type: .daily, expectedCount: 20, persistence: persistence)
                        }
                    }
                }
            }
        }
    }

    @Test func invalidClockPayloadFallsBackSafely() {
        for format in ExerciseFormat.allCases {
            let exercise = Exercise(clockFormat: format, times: [], minuteStep: 1, difficulty: .normal)
            #expect(exercise.format == .solveResult)
            #expect(!exercise.prompt.isEmpty && exercise.options.contains(exercise.correctAnswer))
        }
        let exercise = Exercise(clockFormat: .matchConnect, times: [ClockTime(hour: 3, minute: 0)],
                                minuteStep: 1, difficulty: .normal)
        #expect(exercise.format == .solveResult)
    }

    /// Direct coverage includes formats that random chapter selection never chooses (e.g. clockMatch).
    @Test func everyFormatHasAConstructor() throws {
        let originalLanguage = L.selectedLanguage
        defer { L.selectedLanguage = originalLanguage }
        let suite = "geni.builder-fuzz." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = RecordingPersistence(defaults: defaults)
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for age in 4...10 {
                let profile = ChildProfile(nickname: "Builder", age: age, avatarId: "lion")
                for operation in MathOperation.allCases {
                    for difficulty in difficulties {
                        for format in ExerciseFormat.allCases {
                            let exercise = ExerciseGenerator.build(format, profile: profile, operation: operation, difficulty: difficulty)
                            try verify([exercise], profile: profile, type: .daily, expectedCount: 1, persistence: persistence)
                            if format.isClock && ClockRules.minuteStep(age: age, difficulty: difficulty, format: format) == nil {
                                #expect(exercise.format == .solveResult)
                            } else {
                                #expect(exercise.format == format)
                            }
                            if format == .game {
                                #expect(exercise.game?.kind.ages.contains(age) == true)
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func everyGameBuildsAndCompletesAcrossItsAgesAndDifficulties() throws {
        let originalLanguage = L.selectedLanguage
        defer { L.selectedLanguage = originalLanguage }
        let suite = "geni.game-fuzz." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = RecordingPersistence(defaults: defaults)
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for kind in GameKind.allCases {
                for age in kind.ages {
                    let profile = ChildProfile(nickname: "Games", age: age, avatarId: "lion")
                    for difficulty in difficulties {
                        for _ in 0..<100 {
                            let exercise = GameFactory.make(kind, age: age, difficulty: difficulty)
                            try #require(exercise.game?.kind == kind && exercise.difficulty == difficulty)
                            try verify([exercise], profile: profile, type: .daily, expectedCount: 1, persistence: persistence)
                        }
                    }
                }
            }
        }
    }
}
