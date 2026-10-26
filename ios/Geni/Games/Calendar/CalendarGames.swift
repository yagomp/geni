import SwiftUI

/// Weekdays and seasons (ages 6–7), units of measure (8–10), 3D shapes (9–10).
enum CalendarGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .weekdays: return makeWeekdays(age: age, difficulty: difficulty)
        case .seasons: return makeSeasons(difficulty: difficulty, southern: StoreRegion.isSouthernHemisphere)
        case .units: return makeUnits(difficulty: difficulty, imperial: StoreRegion.usesImperial)
        default: return makeShapes3D(age: age, difficulty: difficulty)
        }
    }

    /// Wraps a built game in the exercise the chapter plays.
    static func exercise(_ kind: GameKind, prompt: String, answerText: String, payload: CalendarPayload,
                         correct: Int, difficulty: ExerciseDifficulty) -> Exercise {
        Exercise(game: GameSpec(kind: kind, prompt: prompt, answerText: answerText, payload: payload),
                 correctAnswer: correct, options: payload.choices.map(\.value), difficulty: difficulty)
    }

    /// The language's own locale for weekday and month names and the first day of the week.
    static var locale: Locale {
        switch L.selectedLanguage {
        case .english: return Locale(identifier: "en_US")
        case .norwegian: return Locale(identifier: "nb_NO")
        case .spanish: return Locale(identifier: "es_ES")
        case .portuguese: return Locale(identifier: "pt_PT")
        }
    }

    static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}

/// What the game proved, so tests can check the facts without parsing prompts.
nonisolated enum CalendarFact: Sendable {
    case weekday(WeekRelation, anchors: [Int], answer: Int)
    case season(month: Int, southern: Bool, answer: Int)
    case unit(UnitSubject, imperial: Bool, answer: MeasureUnit)
    case count(SolidProperty, Solid, answer: Int)
    case rolls(answer: Solid)
    case name(Solid)
}

/// One payload for all four games: the picture, the tiles and how the tiles look.
nonisolated struct CalendarPayload: GamePayload {
    enum Scene: Sendable {
        case week([WeekCell])
        case month(String)
        case emoji(String)
        case solid(Solid)
    }

    enum Style: Sendable {
        case text, emoji, solids
    }

    let scene: Scene
    let style: Style
    let choices: [GameChoice]
    let fact: CalendarFact
}
