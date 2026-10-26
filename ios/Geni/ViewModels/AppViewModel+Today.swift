import Foundation

/// Home presentation only. Daily rewards and the challenge window keep their existing rules.
nonisolated struct TodaySummary: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case mathNotStarted, mathInProgress, requiredReading, optionalReading, complete
    }

    enum NodeState: Equatable, Sendable {
        case done, current, upcoming
    }

    enum Action: Equatable, Sendable {
        case startMath, continueMath, requiredReading, optionalReading

        var identifier: String {
            self == .optionalReading ? "home.optionalReading" : "home.mission"
        }

        var labelKey: LocaleKey {
            switch self {
            case .startMath: return .startMath
            case .continueMath: return .continueChapter
            case .requiredReading, .optionalReading: return .startReading
            }
        }

        var isReading: Bool {
            self == .requiredReading || self == .optionalReading
        }
    }

    let state: State
    let math: NodeState
    let reading: NodeState?
    let mathProgress: Int?
    let readingIsOptional: Bool
    let action: Action?
    let showsExtras: Bool
    let specialChapter: ChapterType?
    let countdown: Int

    var headlineKey: LocaleKey? {
        switch state {
        case .mathNotStarted, .mathInProgress: return nil
        case .requiredReading, .optionalReading: return .mathDone
        case .complete: return .noChapterToday
        }
    }

    var showsComeBackTomorrow: Bool { state == .complete && !showsExtras }

    init(
        todayMathCompleted: Bool,
        todayReadingCompleted: Bool,
        todayChapterInProgress: Bool,
        todayChapterExercisesCompleted: Int,
        readingMode: ReadingRequirement,
        canStartChallengeModes: Bool,
        specialChapterAvailable: ChapterType?,
        countdown: Int
    ) {
        math = todayMathCompleted ? .done : .current
        mathProgress = !todayMathCompleted && todayChapterInProgress
            ? min(20, max(0, todayChapterExercisesCompleted)) : nil
        readingIsOptional = readingMode == .optional
        if readingMode == .hidden {
            reading = nil
        } else if todayReadingCompleted {
            reading = .done
        } else {
            reading = todayMathCompleted ? .current : .upcoming
        }

        if !todayMathCompleted {
            state = todayChapterInProgress ? .mathInProgress : .mathNotStarted
            action = todayChapterInProgress ? .continueMath : .startMath
        } else if readingMode != .hidden && !todayReadingCompleted {
            state = readingIsOptional ? .optionalReading : .requiredReading
            action = readingIsOptional ? .optionalReading : .requiredReading
        } else {
            state = .complete
            action = nil
        }

        showsExtras = canStartChallengeModes
        specialChapter = canStartChallengeModes ? specialChapterAvailable : nil
        self.countdown = max(0, countdown)
    }
}

extension AppViewModel {
    var todaySummary: TodaySummary {
        TodaySummary(
            todayMathCompleted: todayMathCompleted,
            todayReadingCompleted: todayReadingCompleted,
            todayChapterInProgress: todayChapterInProgress,
            todayChapterExercisesCompleted: todayChapterExercisesCompleted,
            readingMode: persistence.activeProfile?.readingMode ?? .hidden,
            canStartChallengeModes: canStartChallengeModes,
            specialChapterAvailable: specialChapterAvailable,
            countdown: challengeSecondsRemaining()
        )
    }
}
