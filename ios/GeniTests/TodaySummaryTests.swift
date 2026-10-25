import Testing
@testable import Geni

struct TodaySummaryTests {
    private func summary(
        mathDone: Bool = false, readingDone: Bool = false,
        inProgress: Bool = false, exercises: Int = 0,
        readingMode: ReadingRequirement = .optional, windowOpen: Bool = false,
        special: ChapterType? = nil, countdown: Int = 0
    ) -> TodaySummary {
        TodaySummary(
            todayMathCompleted: mathDone, todayReadingCompleted: readingDone,
            todayChapterInProgress: inProgress, todayChapterExercisesCompleted: exercises,
            readingMode: readingMode, canStartChallengeModes: windowOpen,
            specialChapterAvailable: special, countdown: countdown
        )
    }

    @Test func aMathNotStarted() {
        let today = summary()
        #expect(today.state == .mathNotStarted)
        #expect(today.math == .current && today.reading == .upcoming)
        #expect(today.mathProgress == nil && today.headlineKey == nil)
        #expect(today.action == .startMath)
        #expect(today.action?.identifier == "home.mission")
        #expect(today.action?.labelKey == .startMath)
        #expect(!today.showsExtras && !today.showsComeBackTomorrow)
    }

    @Test func bMathInProgress() {
        let today = summary(inProgress: true, exercises: 7)
        #expect(today.state == .mathInProgress)
        #expect(today.math == .current && today.reading == .upcoming)
        #expect(today.mathProgress == 7 && today.headlineKey == nil)
        #expect(today.action == .continueMath)
        #expect(today.action?.identifier == "home.mission")
        #expect(today.action?.labelKey == .continueChapter)
        #expect(!today.showsExtras)
    }

    @Test func bPrimeAllAnswersSavedStillNeedsCompletion() {
        let today = summary(inProgress: true, exercises: 20)
        #expect(today.state == .mathInProgress)
        #expect(today.mathProgress == 20 && today.math == .current)
        #expect(today.action == .continueMath)
        #expect(today.action?.identifier == "home.mission")
        #expect(today.headlineKey == nil && !today.showsExtras)
    }

    @Test func cRequiredReadingRemains() {
        let today = summary(mathDone: true, readingMode: .required)
        #expect(today.state == .requiredReading)
        #expect(today.math == .done && today.reading == .current)
        #expect(today.headlineKey == .mathDone && !today.readingIsOptional)
        #expect(today.action == .requiredReading)
        #expect(today.action?.identifier == "home.mission")
        #expect(today.action?.labelKey == .startReading && today.action?.isReading == true)
        #expect(!today.showsExtras && !today.showsComeBackTomorrow)
    }

    @Test(arguments: [false, true]) func dOptionalReadingRemains(windowOpen: Bool) {
        let today = summary(mathDone: true, windowOpen: windowOpen, special: .streak, countdown: 552)
        #expect(today.state == .optionalReading)
        #expect(today.math == .done && today.reading == .current && today.readingIsOptional)
        #expect(today.headlineKey == .mathDone)
        #expect(today.action == .optionalReading)
        #expect(today.action?.identifier == "home.optionalReading")
        #expect(today.action?.labelKey == .startReading && today.action?.isReading == true)
        #expect(today.showsExtras == windowOpen)
        #expect(today.specialChapter == (windowOpen ? .streak : nil))
        #expect(!today.showsComeBackTomorrow)
    }

    @Test(arguments: [ReadingRequirement.optional, .required])
    func eEverythingDone(readingMode: ReadingRequirement) {
        let today = summary(mathDone: true, readingDone: true, readingMode: readingMode, windowOpen: true,
                            special: .boss, countdown: 552)
        #expect(today.state == .complete)
        #expect(today.math == .done && today.reading == .done)
        #expect(today.headlineKey == .noChapterToday)
        #expect(today.action == nil && today.action?.identifier == nil)
        #expect(today.showsExtras && !today.showsComeBackTomorrow)
        #expect(today.specialChapter == .boss && today.countdown == 552)
    }

    @Test func eClosedWindowHasOnlyTomorrowLine() {
        let today = summary(mathDone: true, readingDone: true, special: .boss)
        #expect(today.state == .complete && today.action == nil)
        #expect(today.headlineKey == .noChapterToday)
        #expect(!today.showsExtras && today.specialChapter == nil)
        #expect(today.showsComeBackTomorrow)
    }

    @Test func fHiddenReadingStartsWithSingleMathNode() {
        let today = summary(readingMode: .hidden)
        #expect(today.reading == nil && !today.readingIsOptional)
        #expect(today.math == .current && today.mathProgress == nil)
        #expect(today.state == .mathNotStarted && today.headlineKey == nil)
        #expect(today.action == .startMath && today.action?.identifier == "home.mission")
        #expect(!today.showsExtras)
    }

    @Test(arguments: [7, 20]) func fHiddenReadingInProgress(exercises: Int) {
        let today = summary(inProgress: true, exercises: exercises, readingMode: .hidden)
        #expect(today.reading == nil && today.math == .current)
        #expect(today.mathProgress == exercises && today.state == .mathInProgress)
        #expect(today.headlineKey == nil)
        #expect(today.action == .continueMath && today.action?.identifier == "home.mission")
        #expect(!today.showsExtras)
    }

    @Test(arguments: [false, true]) func fHiddenReadingCompleted(windowOpen: Bool) {
        let today = summary(mathDone: true, readingMode: .hidden, windowOpen: windowOpen)
        #expect(today.state == .complete && today.reading == nil && today.math == .done)
        #expect(today.headlineKey == .noChapterToday && today.action == nil)
        #expect(today.showsExtras == windowOpen)
        #expect(today.showsComeBackTomorrow == !windowOpen)
    }

    @Test func optionalReadingDoneBeforeMathStillDirectsToMath() {
        let today = summary(readingDone: true)
        #expect(today.state == .mathNotStarted && today.math == .current)
        #expect(today.reading == .done && today.readingIsOptional)
        #expect(today.headlineKey == nil && today.action == .startMath)
        #expect(today.action?.identifier == "home.mission" && today.action?.isReading == false)
        #expect(!today.showsExtras)

        let resumed = summary(readingDone: true, inProgress: true, exercises: 7)
        #expect(resumed.reading == .done && resumed.mathProgress == 7)
        #expect(resumed.action == .continueMath && resumed.action?.identifier == "home.mission")
    }

    @Test func ageSixParentReadingSwitchHidesNodeAndOptionalAction() {
        var profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        profile.readingEnabled = false
        let before = summary(readingMode: profile.readingMode)
        #expect(before.reading == nil && before.action?.identifier == "home.mission")
        let after = summary(mathDone: true, readingMode: profile.readingMode)
        #expect(after.state == .complete && after.reading == nil && after.action == nil)
        #expect(after.headlineKey == .noChapterToday)
    }
}
