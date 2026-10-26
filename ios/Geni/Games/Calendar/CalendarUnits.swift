import Foundation

nonisolated enum MeasureCategory: Sendable { case length, mass, volume }

/// Metric units are 0…7, imperial 10…16, so a tile's value tells the unit.
nonisolated enum MeasureUnit: Int, Sendable, CaseIterable {
    case mm = 0, cm, m, km, g, kg, ml, l
    case inch = 10, ft, mi, oz, lb, cup, gal

    static let metric: [MeasureUnit] = [.mm, .cm, .m, .km, .g, .kg, .ml, .l]
    static let imperial: [MeasureUnit] = [.inch, .ft, .mi, .oz, .lb, .cup, .gal]

    var category: MeasureCategory {
        switch self {
        case .mm, .cm, .m, .km, .inch, .ft, .mi: return .length
        case .g, .kg, .oz, .lb: return .mass
        case .ml, .l, .cup, .gal: return .volume
        }
    }

    var label: String {
        switch self {
        case .mm: return "mm"
        case .cm: return "cm"
        case .m: return "m"
        case .km: return "km"
        case .g: return "g"
        case .kg: return "kg"
        case .ml: return "ml"
        case .l: return "L"
        case .inch: return "in"
        case .ft: return "ft"
        case .mi: return "mi"
        case .oz: return "oz"
        case .lb: return "lb"
        case .cup: return L.t("cup", no: "kopp", es: "taza", pt: "chávena")
        case .gal: return "gal"
        }
    }
}

/// Things with one obvious unit. Each lists the units that are far off in the same family
/// (a bus in millimetres), so the harder rounds can tempt without ever being ambiguous.
nonisolated enum UnitSubject: Sendable, CaseIterable {
    case ant, pencil, bus, run, apple, elephant, milk, bath

    var emoji: String {
        switch self {
        case .ant: return "🐜"
        case .pencil: return "✏️"
        case .bus: return "🚌"
        case .run: return "🏃"
        case .apple: return "🍎"
        case .elephant: return "🐘"
        case .milk: return "🥛"
        case .bath: return "🛁"
        }
    }

    func unit(imperial: Bool) -> MeasureUnit {
        switch self {
        case .ant: return imperial ? .inch : .mm
        case .pencil: return imperial ? .inch : .cm
        case .bus: return imperial ? .ft : .m
        case .run: return imperial ? .mi : .km
        case .apple: return imperial ? .oz : .g
        case .elephant: return imperial ? .lb : .kg
        case .milk: return imperial ? .cup : .ml
        case .bath: return imperial ? .gal : .l
        }
    }

    /// Same-family units that are at least a thousand times off (or silly) for this thing.
    func farUnits(imperial: Bool) -> [MeasureUnit] {
        switch self {
        case .ant: return imperial ? [.mi] : [.m, .km]
        case .pencil: return imperial ? [.mi] : [.km]
        case .bus: return imperial ? [.mi] : [.mm, .km]
        case .run: return imperial ? [.inch] : [.mm, .cm]
        case .apple: return []
        case .elephant: return imperial ? [.oz] : [.g]
        case .milk: return imperial ? [.gal] : []
        case .bath: return imperial ? [.cup] : [.ml]
        }
    }

    var prompt: String {
        switch self {
        case .ant:
            return L.t("How long is an ant?", no: "Hvor lang er en maur?",
                       es: "¿Cuánto mide una hormiga?", pt: "Quanto mede uma formiga?")
        case .pencil:
            return L.t("How long is a pencil?", no: "Hvor lang er en blyant?",
                       es: "¿Cuánto mide un lápiz?", pt: "Quanto mede um lápis?")
        case .bus:
            return L.t("How long is a bus?", no: "Hvor lang er en buss?",
                       es: "¿Cuánto mide un autobús?", pt: "Quanto mede um autocarro?")
        case .run:
            return L.t("How far is a long run?", no: "Hvor langt er en lang løpetur?",
                       es: "¿Qué distancia tiene una carrera larga?", pt: "Qual é a distância de uma corrida longa?")
        case .apple:
            return L.t("How heavy is an apple?", no: "Hvor tung er et eple?",
                       es: "¿Cuánto pesa una manzana?", pt: "Quanto pesa uma maçã?")
        case .elephant:
            return L.t("How heavy is an elephant?", no: "Hvor tung er en elefant?",
                       es: "¿Cuánto pesa un elefante?", pt: "Quanto pesa um elefante?")
        case .milk:
            return L.t("How much milk is in a glass?", no: "Hvor mye melk er det i et glass?",
                       es: "¿Cuánta leche hay en un vaso?", pt: "Quanto leite há num copo?")
        case .bath:
            return L.t("How much water fills a bath?", no: "Hvor mye vann er det i et badekar?",
                       es: "¿Cuánta agua cabe en una bañera?", pt: "Quanta água cabe numa banheira?")
        }
    }
}

extension CalendarGames {
    static func makeUnits(difficulty: ExerciseDifficulty, imperial: Bool) -> Exercise {
        let subject = UnitSubject.allCases.randomElement()!
        let answer = subject.unit(imperial: imperial)
        let pool = imperial ? MeasureUnit.imperial : MeasureUnit.metric
        let wrongCount = difficulty == .warmup ? 2 : 3
        let far = subject.farUnits(imperial: imperial)
        let farCount = min(far.count, [0, 1, 2, 2][difficulty.rawValue], wrongCount)
        let others = pool.filter { $0.category != answer.category }
        let wrong = Array(far.shuffled().prefix(farCount)) + Array(others.shuffled().prefix(wrongCount - farCount))
        let choices = ([answer] + wrong).shuffled().map { GameChoice(label: $0.label, value: $0.rawValue) }
        let payload = CalendarPayload(scene: .emoji(subject.emoji), style: .text, choices: choices,
                                      fact: .unit(subject, imperial: imperial, answer: answer))
        return exercise(.units, prompt: subject.prompt, answerText: answer.label, payload: payload,
                        correct: answer.rawValue, difficulty: difficulty)
    }
}
