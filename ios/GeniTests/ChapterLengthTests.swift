import Testing
@testable import Geni

/// Ages 4–5 get 10-exercise chapters (attention span); everyone else 20.
@MainActor
struct ChapterLengthTests {
    @Test(arguments: [4, 5, 6, 7, 9])
    func chapterLengthFollowsDailyExerciseCount(age: Int) {
        let profile = ChildProfile(nickname: "Mo", age: age, avatarId: "lion")
        let expected = age <= 5 ? 10 : 20
        #expect(profile.dailyExerciseCount == expected)
        for _ in 0..<20 {
            #expect(ExerciseGenerator.generateChapter(profile: profile).count == expected)
            #expect(ExerciseGenerator.generateChapter(profile: profile, chapterType: .timeAttack).count == expected)
            #expect(ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: .addition).count == expected)
        }
    }

    @Test(arguments: [4, 5])
    func shortChapterKeepsTheWholeDifficultyRamp(age: Int) {
        let profile = ChildProfile(nickname: "Mo", age: age, avatarId: "lion")
        let difficulties = ExerciseGenerator.generateChapter(profile: profile).map(\.difficulty)
        #expect(difficulties == [.warmup, .warmup, .warmup, .normal, .normal, .harder, .harder, .harder, .challenge, .challenge])
    }

    @Test func perfectShortChapterEarnsFullRewards() {
        let profile = ChildProfile(nickname: "Mo", age: 5, avatarId: "lion")
        let exercises = ExerciseGenerator.generateChapter(profile: profile)
        let vm = ChapterViewModel(profile: profile, chapter: ChapterProgress(childId: profile.id, date: "2026-10-26"), exercises: exercises)
        #expect(vm.chapter.exerciseCount == 10)

        var chapter = vm.chapter
        chapter.exerciseResults = exercises.map {
            ExerciseResult(chapterId: chapter.id, exercise: $0, firstCorrect: true, secondCorrect: nil, attempts: 1)
        }
        chapter.completedExerciseCount = exercises.count
        chapter.calculateRewards()

        #expect(chapter.isComplete)
        #expect(chapter.isFastSolve)
        #expect(chapter.stars == 5)
        #expect(chapter.coinsEarned == 50)
    }

    @Test func fastSolveScalesWithChapterLength() {
        var short = ChapterProgress(childId: "a", date: "2026-10-26", exerciseCount: 10)
        let exercise = Exercise(operand1: 1, operand2: 1, operation: .addition, difficulty: .warmup)
        short.exerciseResults = (0..<10).map {
            ExerciseResult(chapterId: short.id, exercise: exercise, firstCorrect: $0 < 8, secondCorrect: $0 < 8 ? nil : true, attempts: $0 < 8 ? 1 : 2)
        }
        #expect(short.isFastSolve)
        short.exerciseResults[7] = ExerciseResult(chapterId: short.id, exercise: exercise, firstCorrect: false, secondCorrect: true, attempts: 2)
        #expect(!short.isFastSolve)
        #expect(!short.isComplete)

        var long = ChapterProgress(childId: "a", date: "2026-10-26")
        long.exerciseResults = (0..<20).map {
            ExerciseResult(chapterId: long.id, exercise: exercise, firstCorrect: $0 < 15, secondCorrect: $0 < 15 ? nil : true, attempts: $0 < 15 ? 1 : 2)
        }
        #expect(long.isFastSolve)
    }
}
