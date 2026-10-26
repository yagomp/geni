import Foundation
import Testing
@testable import Geni

struct ParentInsightsTests {
    // Monday 2026-10-26 … Sunday 2026-11-01
    private var wednesday: Date {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 10; parts.day = 28; parts.hour = 12
        return Calendar.current.date(from: parts)!
    }

    private func result(_ op: MathOperation, firstTry: Bool, second: Bool? = nil) -> ExerciseResult {
        let json = """
        {"id":"\(UUID().uuidString)","chapterId":"c","prompt":"p","operationType":"\(op.rawValue)","difficulty":1,
         "firstAttemptCorrect":\(firstTry),"attemptsUsed":1,"answeredAt":0\(second.map { ",\"secondAttemptCorrect\":\($0)" } ?? "")}
        """
        return try! JSONDecoder().decode(ExerciseResult.self, from: Data(json.utf8))
    }

    private func chapter(_ date: String, _ results: [ExerciseResult]) -> ChapterProgress {
        var chapter = ChapterProgress(childId: "kid", date: date)
        chapter.exerciseResults = results
        chapter.completedExerciseCount = results.count
        return chapter
    }

    private func reading(_ date: String, completed: Bool = true) -> ReadingSession {
        var session = ReadingSession(childId: "kid", date: date, readingTextId: "t", mode: .readToMe, targetTimeSeconds: 180)
        if completed { session.complete() }
        return session
    }

    @Test func weekRunsMondayToSunday() {
        let week = ParentInsights.weekBounds(containing: wednesday)
        #expect(week.start == "2026-10-26")
        #expect(week.end == "2026-11-01")
    }

    @Test func emptyWeekHasNoNumbers() {
        let summary = ParentInsights.weekSummary(chapters: [], readings: [], today: wednesday)
        #expect(summary == WeekSummary())
    }

    @Test func countsDaysExercisesAccuracyAndReadingInTheWeekOnly() {
        let chapters = [
            chapter("2026-10-26", [result(.addition, firstTry: true), result(.addition, firstTry: false, second: true)]),
            chapter("2026-10-28", [result(.addition, firstTry: false, second: false), result(.addition, firstTry: true)]),
            chapter("2026-10-25", [result(.addition, firstTry: false)]) // previous Sunday
        ]
        let readings = [reading("2026-10-28"), reading("2026-10-29"), reading("2026-10-30", completed: false), reading("2026-10-20")]
        let summary = ParentInsights.weekSummary(chapters: chapters, readings: readings, today: wednesday)
        #expect(summary.exercisesDone == 4)
        #expect(summary.accuracy == 75)
        #expect(summary.readingSessions == 2)
        #expect(summary.daysPracticed == 3) // 26th, 28th, 29th
    }

    @Test func strongestAndHardestNeedEnoughAnswers() {
        let adds = (0..<4).map { _ in result(.addition, firstTry: true) }
        let subs = (0..<4).map { $0 == 0 ? result(.subtraction, firstTry: true) : result(.subtraction, firstTry: false, second: true) }
        let fewMultiplications = [result(.multiplication, firstTry: false), result(.multiplication, firstTry: false)]
        let summary = ParentInsights.weekSummary(chapters: [chapter("2026-10-27", adds + subs + fewMultiplications)],
                                                 readings: [], today: wednesday)
        #expect(summary.strongest == .addition)
        #expect(summary.hardest == .subtraction)
    }

    @Test func noHardestWhenEveryKindIsEqual() {
        let results = (0..<3).map { _ in result(.addition, firstTry: true) } + (0..<3).map { _ in result(.subtraction, firstTry: true) }
        let summary = ParentInsights.weekSummary(chapters: [chapter("2026-10-27", results)], readings: [], today: wednesday)
        #expect(summary.strongest == nil)
        #expect(summary.hardest == nil)
    }

    @Test func everyGameBelongsToATopic() {
        let covered = FocusTopic.allCases.flatMap(\.kinds)
        #expect(Set(covered.map(\.rawValue)) == Set(GameKind.allCases.map(\.rawValue)))
        #expect(covered.count == GameKind.allCases.count)
    }

    @Test func moneyGroupsThePaymentGames() {
        #expect(Set(FocusTopic.money.kinds) == [.moneyPay, .moneyChange, .moneyShopping])
    }

    @Test func topicsAreOfferedByAge() {
        let four = FocusTopic.available(forAge: 4)
        #expect(four.contains(.earlyNumbers))
        #expect(!four.contains(.money))
        #expect(!four.contains(.coding))
        #expect(FocusTopic.available(forAge: 9).contains(.coding))
    }

    @Test func togglingAddsAndRemovesAWholeTopic() {
        let on = ParentInsights.toggling(.money, focus: nil, age: 8)
        #expect(Set(on ?? []) == ["moneyPay", "moneyChange", "moneyShopping"])
        #expect(ParentInsights.isFocused(.money, focus: on, age: 8))

        let two = ParentInsights.toggling(.coding, focus: on, age: 8)
        #expect(two?.contains("codingPath") == true)
        #expect(two?.contains("moneyPay") == true)

        let off = ParentInsights.toggling(.money, focus: two, age: 8)
        #expect(off?.contains("moneyPay") == false)
        #expect(off?.contains("codingPath") == true)
        #expect(ParentInsights.toggling(.coding, focus: off, age: 8) == nil)
    }

    @Test func focusSteersTheChildsGames() {
        var profile = ChildProfile(nickname: "Kid", age: 8, avatarId: "fox")
        profile.focusGames = ParentInsights.toggling(.money, focus: nil, age: 8)
        let kinds = GameCurriculum.kinds(for: profile)
        #expect(Set(kinds) == [.moneyPay, .moneyChange, .moneyShopping])
        #expect(ParentInsights.upcomingTopics(for: profile) == [.money])
    }

    @Test func upcomingTopicsAreDistinctAndLimited() {
        let profile = ChildProfile(nickname: "Kid", age: 5, avatarId: "fox")
        let topics = ParentInsights.upcomingTopics(for: profile)
        #expect(topics.count <= 3)
        #expect(Set(topics).count == topics.count)
    }
}
