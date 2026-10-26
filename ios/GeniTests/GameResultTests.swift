import Foundation
import Testing
@testable import Geni

@MainActor
struct GameResultTests {
    private func result(_ exercise: Exercise, correct: Bool = true) -> ExerciseResult {
        ExerciseResult(chapterId: "c", exercise: exercise, firstCorrect: correct, secondCorrect: nil, attempts: 1)
    }

    @Test func resultsPersistGameOriginAndLegacyResultsStillDecode() throws {
        let game = CodingGames.make(.codingPath, age: 7, difficulty: .normal)
        let data = try JSONEncoder().encode(result(game))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["gameKind"] as? String == "codingPath")
        let restored = try JSONDecoder().decode(ExerciseResult.self, from: data)
        let roundTrip = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(restored)) as? [String: Any])
        #expect(roundTrip["gameKind"] as? String == "codingPath")

        var legacy = object
        legacy.removeValue(forKey: "gameKind")
        let oldResult = try JSONDecoder().decode(ExerciseResult.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(oldResult.operationType == game.operation)
        #expect(oldResult.wasCorrect)
    }

    @Test func gamesCountInActivityButNotOperationComparisons() throws {
        let today = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
        let addition = Exercise(operand1: 2, operand2: 3, operation: .addition, difficulty: .normal)
        let subtraction = Exercise(operand1: 5, operand2: 3, operation: .subtraction, difficulty: .normal)
        // These default to addition, but are not evidence of arithmetic skill.
        let picture = CodingGames.make(.codingPath, age: 7, difficulty: .normal)
        let story = StoryGames.make(.timesGroups, age: 8, difficulty: .normal)
        var chapter = ChapterProgress(childId: "kid", date: "2026-10-28")
        chapter.exerciseResults = (0..<3).map { result(addition, correct: $0 < 2) }
            + (0..<3).map { result(subtraction, correct: $0 < 1) }
            + (0..<20).map { _ in result(picture, correct: false) }
            + (0..<3).map { _ in result(story) }
        let summary = ParentInsights.weekSummary(chapters: [chapter], readings: [], today: today)
        #expect(summary.exercisesDone == 29)
        #expect(summary.daysPracticed == 1)
        #expect(summary.accuracy == 21)
        #expect(summary.strongest == .addition)
        #expect(summary.hardest == .subtraction)

        chapter.exerciseResults = (0..<3).map { _ in result(picture, correct: false) }
            + (0..<3).map { _ in result(story) }
        let gamesOnly = ParentInsights.weekSummary(chapters: [chapter], readings: [], today: today)
        #expect(gamesOnly.strongest == nil)
        #expect(gamesOnly.hardest == nil)
    }

    @Test func multiplicationBadgeRequiresArithmeticRatherThanAStoryGame() {
        let device = TestDevice()
        let vm = device.makeViewModel()
        let profile = ChildProfile(nickname: "Badges", age: 8, avatarId: "fox")
        vm.completeOnboarding(profile: profile)
        let story = StoryGames.make(.timesGroups, age: 8, difficulty: .normal)
        #expect(story.operation == .multiplication)
        var chapter = ChapterProgress(childId: profile.id, date: "2026-10-28")
        chapter.exerciseResults = [result(story)]
        vm.completeChapter(chapter)
        #expect(!vm.rewardState.badgesUnlocked.contains("mul_master"))

        let arithmetic = Exercise(operand1: 3, operand2: 2, operation: .multiplication, difficulty: .normal)
        var next = ChapterProgress(childId: profile.id, date: "2026-10-29")
        next.exerciseResults = [result(arithmetic)]
        vm.completeChapter(next)
        #expect(vm.rewardState.badgesUnlocked.contains("mul_master"))
    }
}
