import Foundation

extension CalendarGames {
    /// Picture for each season, indexed by season: 0 winter, 1 spring, 2 summer, 3 autumn.
    static let seasonPictures = ["❄️", "🌸", "☀️", "🍂"]

    /// Meteorological seasons; south of the equator they are six months apart.
    static func season(month: Int, southern: Bool) -> Int {
        let northMonth = southern ? (month + 5) % 12 + 1 : month
        switch northMonth {
        case 12, 1, 2: return 0
        case 3, 4, 5: return 1
        case 6, 7, 8: return 2
        default: return 3
        }
    }

    static func makeSeasons(difficulty: ExerciseDifficulty, southern: Bool) -> Exercise {
        // The middle month of each season first; the in-between months (March, June…) come later.
        let months: [Int]
        switch difficulty {
        case .warmup: months = [1, 4, 7, 10]
        case .normal: months = [1, 2, 4, 5, 7, 8, 10, 11]
        case .harder, .challenge: months = Array(1...12)
        }
        let month = months.randomElement()!
        let answer = season(month: month, southern: southern)
        let wrongCount = difficulty == .warmup ? 2 : 3
        let wrong = (0..<4).filter { $0 != answer }.shuffled().prefix(wrongCount)
        let choices = ([answer] + wrong).shuffled().map { GameChoice(label: seasonPictures[$0], value: $0) }

        let formatter = DateFormatter()
        formatter.locale = locale
        let name = formatter.standaloneMonthSymbols[month - 1]
        let prompt = L.t("Which season is \(name)?", no: "Hvilken årstid er \(name)?",
                         es: "¿Qué estación es \(name)?", pt: "Que estação é \(name)?")
        let payload = CalendarPayload(scene: .month(capitalized(name)), style: .emoji, choices: choices,
                                      fact: .season(month: month, southern: southern, answer: answer))
        return exercise(.seasons, prompt: prompt, answerText: seasonPictures[answer], payload: payload,
                        correct: answer, difficulty: difficulty)
    }
}
