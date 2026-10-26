import Foundation

/// Parent-friendly topics that group the picture games, for the "School is working on" picker.
nonisolated enum FocusTopic: String, CaseIterable, Sendable {
    case earlyNumbers, numberSense, tensAndOnes, money, shapes, calendar, coding, data, stories

    var emoji: String {
        switch self {
        case .earlyNumbers: return "🧸"
        case .numberSense: return "➕"
        case .tensAndOnes: return "🔟"
        case .money: return "🪙"
        case .shapes: return "🔺"
        case .calendar: return "📅"
        case .coding: return "🤖"
        case .data: return "📊"
        case .stories: return "📖"
        }
    }

    var name: String {
        switch self {
        case .earlyNumbers: return L.t("Early numbers", no: "Tidlige tall", es: "Primeros números", pt: "Primeiros números")
        case .numberSense: return L.t("Number sense", no: "Tallforståelse", es: "Sentido numérico", pt: "Sentido numérico")
        case .tensAndOnes: return L.t("Tens & ones", no: "Tiere og enere", es: "Decenas y unidades", pt: "Dezenas e unidades")
        case .money: return L.t("Money", no: "Penger", es: "Dinero", pt: "Dinheiro")
        case .shapes: return L.t("Shapes & patterns", no: "Former og mønstre", es: "Formas y patrones", pt: "Formas e padrões")
        case .calendar: return L.t("Calendar & units", no: "Kalender og enheter", es: "Calendario y unidades", pt: "Calendário e unidades")
        case .coding: return L.t("Coding", no: "Koding", es: "Programación", pt: "Programação")
        case .data: return L.t("Data", no: "Data", es: "Datos", pt: "Dados")
        case .stories: return L.t("Stories", no: "Fortellinger", es: "Historias", pt: "Histórias")
        }
    }

    init(_ kind: GameKind) {
        switch kind {
        case .ordinal, .position, .fingerNumbers, .bigSmall: self = .earlyNumbers
        case .tenFriends, .doubles, .numberNeighbours, .countBackwards, .skipCounting: self = .numberSense
        case .numberLine, .tensOnes: self = .tensAndOnes
        case .moneyPay, .moneyChange, .moneyShopping: self = .money
        case .patternNext, .shapeFind, .oddOneOut, .symmetry, .shapes3D: self = .shapes
        case .weekdays, .seasons, .units: self = .calendar
        case .codingPath, .codingLoop: self = .coding
        case .tallyChart, .barChart, .estimate: self = .data
        case .timesGroups, .fairShare, .storyMatch: self = .stories
        }
    }

    /// Every game in this topic, whatever the age.
    var kinds: [GameKind] { GameKind.allCases.filter { FocusTopic($0) == self } }

    /// Topics with at least one game for this age, in picker order.
    static func available(forAge age: Int) -> [FocusTopic] {
        let age = min(max(age, 4), 10)
        return allCases.filter { topic in topic.kinds.contains { $0.ages.contains(age) } }
    }
}

nonisolated struct WeekSummary: Equatable, Sendable {
    var daysPracticed = 0
    var exercisesDone = 0
    /// Percent of answers right, nil before the first answer.
    var accuracy: Int?
    var readingSessions = 0
    var strongest: MathOperation?
    var hardest: MathOperation?
}

/// Pure computations behind the parent area's "This week" and focus picker.
nonisolated enum ParentInsights {
    /// A kind needs this many answers in the week before it counts as strongest or hardest.
    static let minimumAnswersPerKind = 3

    static let dateFormat = "yyyy-MM-dd"

    /// RewardState.xp is the balance within its level; completed levels cost 200, 400, 600, … XP.
    static func lifetimeXP(for rewards: RewardState) -> Int {
        rewards.xp + 100 * rewards.level * (rewards.level - 1)
    }

    /// The Monday–Sunday week containing `today`, as stored dates (`yyyy-MM-dd`, lexicographically ordered).
    static func weekBounds(containing today: Date, calendar: Calendar = .current) -> (start: String, end: String) {
        var cal = calendar
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? today
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.dateFormat = dateFormat
        return (fmt.string(from: start), fmt.string(from: end))
    }

    static func weekSummary(chapters: [ChapterProgress], readings: [ReadingSession],
                            today: Date = Date(), calendar: Calendar = .current) -> WeekSummary {
        let week = weekBounds(containing: today, calendar: calendar)
        let inWeek: (String) -> Bool = { $0 >= week.start && $0 <= week.end }

        let weekChapters = chapters.filter { inWeek($0.date) && !$0.exerciseResults.isEmpty }
        let weekReadings = readings.filter { inWeek($0.date) && $0.isCompleted }
        let results = weekChapters.flatMap(\.exerciseResults)

        var summary = WeekSummary()
        summary.daysPracticed = Set(weekChapters.map(\.date) + weekReadings.map(\.date)).count
        summary.exercisesDone = results.count
        summary.readingSessions = weekReadings.count
        if !results.isEmpty {
            summary.accuracy = Int((Double(results.filter(\.wasCorrect).count) / Double(results.count) * 100).rounded())
        }

        let rates: [(op: MathOperation, rate: Double)] = MathOperation.allCases.compactMap { op in
            let answers = results.filter { $0.gameKind == nil && $0.operationType == op }
            guard answers.count >= minimumAnswersPerKind else { return nil }
            return (op, Double(answers.filter(\.firstAttemptCorrect).count) / Double(answers.count))
        }
        if let best = rates.max(by: { $0.rate < $1.rate }), let worst = rates.min(by: { $0.rate < $1.rate }),
           best.rate > worst.rate {
            summary.strongest = best.op
            summary.hardest = worst.op
        }
        return summary
    }

    /// Topics of the games a child meets next, most recent focus first; at most `limit`.
    static func upcomingTopics(for profile: ChildProfile, limit: Int = 3) -> [FocusTopic] {
        var seen: [FocusTopic] = []
        for kind in GameCurriculum.kinds(for: profile) {
            let topic = FocusTopic(kind)
            if !seen.contains(topic) { seen.append(topic) }
        }
        return Array(seen.prefix(limit))
    }

    /// Whether this age's games of `topic` are in the child's focus.
    static func isFocused(_ topic: FocusTopic, focus: [String]?, age: Int) -> Bool {
        let focused = Set(focus ?? [])
        let age = min(max(age, 4), 10)
        return topic.kinds.contains { $0.ages.contains(age) && focused.contains($0.rawValue) }
    }

    /// The saved focus after tapping `topic`; nil when nothing is left.
    static func toggling(_ topic: FocusTopic, focus: [String]?, age: Int) -> [String]? {
        var focused = focus ?? []
        let ownKinds = Set(topic.kinds.map(\.rawValue))
        if isFocused(topic, focus: focus, age: age) {
            focused.removeAll { ownKinds.contains($0) }
        } else {
            focused += topic.kinds.map(\.rawValue).filter { !focused.contains($0) }
        }
        return focused.isEmpty ? nil : focused
    }
}
