import Foundation

/// 0 = Sunday … 6 = Saturday, like `Calendar` weekday symbols.
nonisolated enum WeekRelation: Sendable, CaseIterable {
    case after, before, between, twoAfter, twoBefore
}

nonisolated struct WeekCell: Sendable, Equatable {
    enum State: Sendable { case shown, anchor, blank, missing }
    let label: String
    let state: State
}

extension CalendarGames {
    static func makeWeekdays(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let relation = weekRelation(age: age, difficulty: difficulty)
        let anchor = Int.random(in: 0..<7)
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
        let short = shortWeekdayNames()
        // Full week for the youngest and the easy rounds; later only the days the question names.
        let showAll = difficulty == .warmup || (age <= 6 && difficulty == .normal)
        let order = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 }
        let cells = order.map { day -> WeekCell in
            if day == answer { return WeekCell(label: "?", state: .missing) }
            if anchors.contains(day) { return WeekCell(label: short[day], state: .anchor) }
            return WeekCell(label: showAll ? short[day] : "", state: showAll ? .shown : .blank)
        }

        let wrongCount = difficulty == .warmup ? 2 : 3
        let wrong = (0..<7).filter { $0 != answer && !anchors.contains($0) }.shuffled().prefix(wrongCount)
        let choices = ([answer] + wrong).shuffled().map { GameChoice(label: short[$0], value: $0) }
        let payload = CalendarPayload(scene: .week(cells), style: .text, choices: choices,
                                      fact: .weekday(relation, anchors: anchors, answer: answer))
        return exercise(.weekdays, prompt: weekdayPrompt(relation, names: anchors.map { full[$0] }),
                        answerText: short[answer], payload: payload, correct: answer, difficulty: difficulty)
    }

    static func weekRelation(age: Int, difficulty: ExerciseDifficulty) -> WeekRelation {
        switch difficulty {
        case .warmup, .normal: return [.after, .before].randomElement()!
        case .harder: return (age >= 7 ? [.after, .before, .between] : [.after, .before]).randomElement()!
        case .challenge: return (age >= 7 ? [.between, .twoAfter, .twoBefore] : [.after, .before]).randomElement()!
        }
    }

    static func weekCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }

    private static func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter
    }

    /// "Monday" / "mandag" / "lunes" / "segunda-feira", indexed 0 = Sunday.
    static func fullWeekdayNames() -> [String] {
        formatter().standaloneWeekdaySymbols
    }

    /// "Mon" / "Man" / "Lun" / "Seg" for the cards and tiles, indexed 0 = Sunday.
    static func shortWeekdayNames() -> [String] {
        formatter().shortStandaloneWeekdaySymbols.map { capitalized($0.replacingOccurrences(of: ".", with: "")) }
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
