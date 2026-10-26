import Foundation

/// Home presentation only. Daily rewards and the challenge window keep their existing rules.
nonisolated struct TodaySummary: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case mathNotStarted, mathInProgress, requiredReading, optionalReading, complete
    }

    enum NodeState: Equatable, Sendable {
        case done, current
    }

    enum Action: Equatable, Sendable {
        case startMath, continueMath, reading

        var identifier: String {
            self == .reading ? "home.reading" : "home.math"
        }

        var labelKey: LocaleKey {
            switch self {
            case .startMath: return .startMath
            case .continueMath: return .continueChapter
            case .reading: return .startReading
            }
        }
    }

    let state: State
    let math: NodeState
    let reading: NodeState?
    let mathProgress: Int?
    /// Exercises in today's chapter (10 for ages 4–5, otherwise 20).
    let chapterLength: Int
    /// "🔟 Crossing ten" for ages 7+ (their topic path); nil for younger children.
    var mathTopic: String? = nil
    /// Today's reading goal in minutes (3 at age 6, 5 at 7–8, 7 from 9).
    var readingMinutes = 3
    let readingIsOptional: Bool
    /// Math and reading start independently, in whichever order the child picks.
    let mathAction: Action?
    let readingAction: Action?
    let showsExtras: Bool
    let specialChapter: ChapterType?
    let countdown: Int

    var showsComeBackTomorrow: Bool { state == .complete && !showsExtras }

    init(
        todayMathCompleted: Bool,
        todayReadingCompleted: Bool,
        todayChapterInProgress: Bool,
        todayChapterExercisesCompleted: Int,
        chapterLength: Int = 20,
        readingMode: ReadingRequirement,
        canStartChallengeModes: Bool,
        specialChapterAvailable: ChapterType?,
        countdown: Int
    ) {
        math = todayMathCompleted ? .done : .current
        mathProgress = !todayMathCompleted && todayChapterInProgress
            ? min(chapterLength, max(0, todayChapterExercisesCompleted)) : nil
        self.chapterLength = chapterLength
        mathAction = todayMathCompleted ? nil : (todayChapterInProgress ? .continueMath : .startMath)
        readingIsOptional = readingMode == .optional
        if readingMode == .hidden {
            reading = nil
            readingAction = nil
        } else {
            reading = todayReadingCompleted ? .done : .current
            readingAction = todayReadingCompleted ? nil : .reading
        }

        if !todayMathCompleted {
            state = todayChapterInProgress ? .mathInProgress : .mathNotStarted
        } else if readingMode != .hidden && !todayReadingCompleted {
            state = readingIsOptional ? .optionalReading : .requiredReading
        } else {
            state = .complete
        }

        showsExtras = canStartChallengeModes
        specialChapter = canStartChallengeModes ? specialChapterAvailable : nil
        self.countdown = max(0, countdown)
    }
}

extension AppViewModel {
    var todaySummary: TodaySummary {
        let profile = persistence.activeProfile
        var summary = TodaySummary(
            todayMathCompleted: todayMathCompleted,
            todayReadingCompleted: todayReadingCompleted,
            todayChapterInProgress: todayChapterInProgress,
            todayChapterExercisesCompleted: todayChapterExercisesCompleted,
            chapterLength: persistence.activeProfile?.dailyExerciseCount ?? 20,
            readingMode: persistence.activeProfile?.readingMode ?? .hidden,
            canStartChallengeModes: canStartChallengeModes,
            specialChapterAvailable: specialChapterAvailable,
            countdown: challengeSecondsRemaining()
        )
        if let profile {
            summary.readingMinutes = ReadingText.targetReadingSeconds(for: profile.age) / 60
        }
        if let profile, profile.ageGroup != .young {
            let topic = topicProgress.currentTopic()
            summary.mathTopic = "\(topic.emoji) \(topic.displayName)"
        }
        return summary
    }
}
