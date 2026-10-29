import Foundation

/// 0 = Sunday … 6 = Saturday, like `Calendar` weekday symbols.
nonisolated enum WeekRelation: Sendable, CaseIterable {
    case after, before, between, twoAfter, twoBefore
}

nonisolated struct WeekCell: Sendable, Equatable {
    /// `missing` is the gap the child fills; its label is the answer, shown once it's solved.
    enum State: Sendable { case shown, anchor, missing }
    let label: String
    let state: State
}

extension CalendarGames {
    static func makeWeekdays(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        weekdayGame(weekRelation(age: age, difficulty: difficulty), anchor: Int.random(in: 0..<7), difficulty: difficulty)
    }

    /// One weekday question about `anchor` (0 = Sunday). `distractors` fixes the wrong tiles and their order
    /// (design previews); otherwise they are random.
    static func weekdayGame(_ relation: WeekRelation, anchor: Int, difficulty: ExerciseDifficulty,
                            distractors: [Int]? = nil) -> Exercise {
        let anchors: [Int]
        let answer: Int
        switch relation {
        case .after: anchors = [anchor]; answer = (anchor + 1) % 7
        case .before: anchors = [anchor]; answer = (anchor + 6) % 7
        case .between: anchors = [anchor, (anchor + 2) % 7]; answer = (anchor + 1) % 7
        case .twoAfter: anchors = [anchor]; answer = (anchor + 2) % 7
        case .twoBefore: anchors = [anchor]; answer = (anchor + 5) % 7
        }

        let calendar = weekCalendar()
        let full = fullWeekdayNames()
        // The whole week in the locale's order, every day named in full; only the asked day is a gap
        // (its cell keeps the name so the view can fill it in once answered).
        let order = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 }
        let cells = order.map { day in
            WeekCell(label: full[day], state: day == answer ? .missing : anchors.contains(day) ? .anchor : .shown)
        }

        let wrongCount = difficulty == .warmup ? 2 : 3
        let wrong = (0..<7).filter { $0 != answer && !anchors.contains($0) }.shuffled().prefix(wrongCount)
        let choices = (distractors.map { [answer] + $0 } ?? ([answer] + wrong).shuffled())
            .map { GameChoice(label: full[$0], value: $0) }
        let payload = CalendarPayload(scene: .week(cells), style: .text, choices: choices,
                                      fact: .weekday(relation, anchors: anchors, answer: answer))
        return exercise(.weekdays, prompt: weekdayPrompt(relation, names: anchors.map { full[$0] }),
                        answerText: full[answer], payload: payload, correct: answer, difficulty: difficulty)
    }

    static func weekRelation(age: Int, difficulty: ExerciseDifficulty) -> WeekRelation {
        switch difficulty {
        case .warmup, .normal: return [.after, .before].randomElement()!
        case .harder: return (age >= 7 ? [.after, .before, .between] : [.after, .before]).randomElement()!
        case .challenge: return (age >= 7 ? [.between, .twoAfter, .twoBefore] : [.after, .before]).randomElement()!
        }
    }

    /// Weeks start on Sunday in English (US) and on Monday in Norwegian, Spanish and Portuguese
    /// (pt_PT's locale says Sunday, but Portuguese school weeks start on Monday).
    static func weekCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.firstWeekday = L.selectedLanguage == .english ? 1 : 2
        return calendar
    }

    private static func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter
    }

    /// "Monday" / "mandag" / "lunes" / "segunda-feira", indexed 0 = Sunday. Full names everywhere:
    /// children learning the week need the word they hear, in the same spelling as the question.
    static func fullWeekdayNames() -> [String] {
        formatter().standaloneWeekdaySymbols
    }

    static func weekdayPrompt(_ relation: WeekRelation, names n: [String]) -> String {
        switch relation {
        case .after:
            return L.t("Which day comes after \(n[0])?", no: "Hvilken dag kommer etter \(n[0])?",
                       es: "¿Qué día viene después del \(n[0])?", pt: "Que dia vem depois de \(n[0])?")
        case .before:
            return L.t("Which day comes before \(n[0])?", no: "Hvilken dag kommer før \(n[0])?",
                       es: "¿Qué día viene antes del \(n[0])?", pt: "Que dia vem antes de \(n[0])?")
        case .between:
            return L.t("Which day is between \(n[0]) and \(n[1])?", no: "Hvilken dag er mellom \(n[0]) og \(n[1])?",
                       es: "¿Qué día está entre el \(n[0]) y el \(n[1])?", pt: "Que dia está entre \(n[0]) e \(n[1])?")
        case .twoAfter:
            return L.t("Which day is two days after \(n[0])?", no: "Hvilken dag er to dager etter \(n[0])?",
                       es: "¿Qué día es dos días después del \(n[0])?", pt: "Que dia é dois dias depois de \(n[0])?")
        case .twoBefore:
            return L.t("Which day is two days before \(n[0])?", no: "Hvilken dag er to dager før \(n[0])?",
                       es: "¿Qué día es dos días antes del \(n[0])?", pt: "Que dia é dois dias antes de \(n[0])?")
        }
    }
}
