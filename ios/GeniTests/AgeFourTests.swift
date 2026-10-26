import Testing
@testable import Geni

/// Age 4: pictures only, numbers up to 5, no reading, addition only.
@MainActor
struct AgeFourTests {
    private let pictureFormats: Set<ExerciseFormat> = [.countingObjects, .compareGroups, .tenFrame, .visualAddition]

    private func chapters(_ profile: ChildProfile) -> [[Exercise]] {
        var all: [[Exercise]] = []
        for _ in 0..<100 {
            all.append(ExerciseGenerator.generateChapter(profile: profile))
            all.append(ExerciseGenerator.generateChapter(profile: profile, chapterType: .timeAttack))
            all.append(ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: .subtraction))
        }
        return all
    }

    @Test func profileDefaults() {
        let profile = ChildProfile(nickname: "Mo", age: 4, avatarId: "lion")
        #expect(ProfileDraft.ages.contains(4))
        #expect(profile.ageGroup == .young)
        #expect(profile.readingMode == .hidden)
        #expect(profile.operationsEnabled == [.addition])
    }

    @Test func everyChapterTypeIsTenPictureExercisesUpToFive() {
        let profile = ChildProfile(nickname: "Mo", age: 4, avatarId: "lion")
        for chapter in chapters(profile) {
            #expect(chapter.count == 10)
            for exercise in chapter where exercise.format != .game {
                #expect(pictureFormats.contains(exercise.format))
                #expect(exercise.shouldShowEmojiCounting)
                switch exercise.format {
                case .compareGroups:
                    #expect(max(exercise.operand1, exercise.operand2) <= 5)
                    #expect(abs(exercise.operand1 - exercise.operand2) >= 2)
                    #expect(min(exercise.operand1, exercise.operand2) >= 1)
                default:
                    #expect((1...5).contains(exercise.correctAnswer))
                    #expect(exercise.options.count == 4)
                    #expect(Set(exercise.options).count == 4)
                    #expect(exercise.options.contains(exercise.correctAnswer))
                    #expect(exercise.options.allSatisfy { (1...6).contains($0) })
                }
            }
        }
    }

    @Test func warmupStaysWithinThree() {
        let profile = ChildProfile(nickname: "Mo", age: 4, avatarId: "lion")
        for _ in 0..<100 {
            let warmup = ExerciseGenerator.generateChapter(profile: profile).filter { $0.difficulty == .warmup }
            #expect(warmup.count == 3)
            for exercise in warmup where exercise.format != .compareGroups && exercise.format != .game {
                #expect(exercise.correctAnswer <= 3)
            }
        }
    }
}
