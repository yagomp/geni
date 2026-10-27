import Foundation

/// Every picture game. Grouped by the folder (and agent/owner) that implements it.
nonisolated enum GameKind: String, CaseIterable, Sendable {
    // EarlyYears/ — ages 4–5
    case ordinal, position, fingerNumbers, bigSmall
    // Shapes/ — ages 4–6
    case patternNext, shapeFind, oddOneOut
    // NumberSense/ — ages 5–8
    case tenFriends, doubles, numberNeighbours, countBackwards, skipCounting
    // Money/ — ages 6–10, currency from the App Store storefront
    case moneyPay, moneyChange, moneyShopping
    // PlaceValue/ — ages 7–9
    case numberLine, tensOnes
    // Calendar/ — ages 6–10
    case weekdays, seasons, units, shapes3D
    // Coding/ — ages 7–10
    case codingPath, codingLoop, symmetry
    // Data/ — ages 7–10
    case tallyChart, barChart, estimate
    // Stories/ — ages 8–10
    case timesGroups, fairShare, storyMatch

    /// Ages that get this game in daily chapters.
    var ages: ClosedRange<Int> {
        switch self {
        case .ordinal, .position, .fingerNumbers: return 4...5
        case .bigSmall: return 4...4
        case .patternNext, .oddOneOut: return 4...6
        case .shapeFind: return 4...5
        case .tenFriends: return 5...7
        case .numberNeighbours: return 5...6
        case .doubles, .weekdays, .seasons: return 6...7
        case .countBackwards: return 6...6
        case .skipCounting, .tensOnes, .symmetry, .tallyChart: return 7...8
        case .moneyPay: return 6...8
        case .moneyShopping: return 7...10
        case .moneyChange, .units: return 8...10
        case .numberLine, .codingPath, .barChart: return 7...9
        case .shapes3D, .codingLoop, .estimate, .fairShare, .storyMatch: return 9...10
        case .timesGroups: return 8...9
        }
    }
}

/// Game-specific data. Each game folder defines its own payload type(s).
protocol GamePayload: Sendable {}

nonisolated struct GameSpec: Sendable {
    let kind: GameKind
    /// The one question line: shown on screen and read aloud for ages 4–5. Localized.
    let prompt: String
    /// Shown in the feedback banner after two misses, e.g. "🐸" or "7" or "3 kr".
    let answerText: String
    let payload: any GamePayload
}

/// One tap target in a pick-one game: a big emoji, number or short word.
nonisolated struct GameChoice: Sendable, Equatable {
    let label: String
    let value: Int
}

/// The common game shape: a scene of pictures, then 2–4 choices. Rendered by `ChoiceGameView`.
nonisolated struct ChoicePayload: GamePayload {
    /// Rows of emoji/short labels drawn as the picture (one row per array).
    let scene: [[String]]
    let choices: [GameChoice]
}

extension Exercise {
    /// A pick-one game: the right choice's `value` is the answer.
    static func choiceGame(_ kind: GameKind, prompt: String, scene: [[String]], choices: [GameChoice],
                           correct: GameChoice, difficulty: ExerciseDifficulty) -> Exercise {
        Exercise(
            game: GameSpec(kind: kind, prompt: prompt, answerText: correct.label,
                           payload: ChoicePayload(scene: scene, choices: choices)),
            correctAnswer: correct.value,
            options: choices.map(\.value),
            difficulty: difficulty
        )
    }
}

/// Builds one exercise of a game kind. Each folder's `make` owns its kinds.
enum GameFactory {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .ordinal, .position, .fingerNumbers, .bigSmall:
            return EarlyYearsGames.make(kind, age: age, difficulty: difficulty)
        case .patternNext, .shapeFind, .oddOneOut:
            return ShapeGames.make(kind, age: age, difficulty: difficulty)
        case .tenFriends, .doubles, .numberNeighbours, .countBackwards, .skipCounting:
            return NumberSenseGames.make(kind, age: age, difficulty: difficulty)
        case .moneyPay, .moneyChange, .moneyShopping:
            return MoneyGames.make(kind, age: age, difficulty: difficulty)
        case .numberLine, .tensOnes:
            return PlaceValueGames.make(kind, age: age, difficulty: difficulty)
        case .weekdays, .seasons, .units, .shapes3D:
            return CalendarGames.make(kind, age: age, difficulty: difficulty)
        case .codingPath, .codingLoop, .symmetry:
            return CodingGames.make(kind, age: age, difficulty: difficulty)
        case .tallyChart, .barChart, .estimate:
            return DataGames.make(kind, age: age, difficulty: difficulty)
        case .timesGroups, .fairShare, .storyMatch:
            return StoryGames.make(kind, age: age, difficulty: difficulty)
        }
    }
}

/// Which games a child meets, and where they sit in a daily chapter.
enum GameCurriculum {
    /// Chapter slots (0-based) that become games; warmup stays the familiar format and
    /// age 6's clock slots (6 and 14) stay clocks.
    static func slots(chapterLength: Int) -> [Int] {
        chapterLength <= 10 ? [3, 6, 9] : [4, 9, 12, 17]
    }

    static func kinds(for profile: ChildProfile) -> [GameKind] {
        let forAge = GameKind.allCases.filter { $0.ages.contains(min(max(profile.age, 4), 10)) }
        let focus = Set((profile.focusGames ?? []).compactMap(GameKind.init(rawValue:)))
        let focused = forAge.filter { focus.contains($0) }
        return focused.isEmpty ? forAge : focused
    }

    /// Regular UI tests keep their existing curriculum; the opt-in demo records games.
    static var isEnabled: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-demoGames") { return true }
        #endif
        return !ProcessInfo.processInfo.arguments.contains("-uiTest")
    }

    /// Replaces the game slots of a daily chapter with this child's games, round-robin from a random start.
    static func insertGames(into exercises: [Exercise], profile: ChildProfile) -> [Exercise] {
        let kinds = kinds(for: profile)
        guard isEnabled, !kinds.isEmpty else { return exercises }
        var result = exercises
        #if DEBUG
        // A short, repeatable opening for the opt-in marketing recording. Keep the
        // normal chapter length, feedback, persistence and remaining curriculum.
        if ProcessInfo.processInfo.arguments.contains("-demoRecording"), profile.age == 6, result.count >= 4 {
            result[0] = Exercise(operand1: 2, operand2: 3, operation: .addition, difficulty: .warmup)
            if let game = DesignPreview.captureGame(.tenFriends) { result[1] = game }
            if let game = DesignPreview.captureGame(.doubles) { result[2] = game }
            result[3] = Exercise(operand1: 9, operand2: 4, operation: .subtraction, difficulty: .warmup)
            return result
        }
        #endif
        let start = Int.random(in: 0..<kinds.count)
        for (n, slot) in slots(chapterLength: exercises.count).enumerated() where slot < result.count {
            let kind = kinds[(start + n) % kinds.count]
            result[slot] = GameFactory.make(kind, age: profile.age, difficulty: result[slot].difficulty)
        }
        return result
    }
}
