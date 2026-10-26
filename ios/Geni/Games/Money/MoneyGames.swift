import SwiftUI

nonisolated struct MoneyItem: Sendable, Equatable {
    let emoji: String
    let price: Int
}

nonisolated struct MoneyPayPayload: GamePayload {
    let currency: MoneyCurrency
    let item: MoneyItem
    let tray: [MoneyDenomination]
}

nonisolated struct MoneyShoppingPayload: GamePayload {
    let currency: MoneyCurrency
    let items: [MoneyItem]
    let choices: [GameChoice]
}

nonisolated struct MoneyChangePayload: GamePayload {
    let currency: MoneyCurrency
    let item: MoneyItem
    let note: MoneyDenomination
    let choices: [GameChoice]
}

enum MoneyGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        make(kind, age: age, difficulty: difficulty, currency: .storefront)
    }

    /// Explicit currency makes storefront rules testable without changing account settings.
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty, currency: MoneyCurrency) -> Exercise {
        switch kind {
        case .moneyPay:
            let limit = payLimit(age: age)
            let price = Int.random(in: 1...limit)
            return exercise(kind, prompt: L.t("Can you pay?", no: "Kan du betale?", es: "¿Puedes pagar?", pt: "Consegues pagar?"),
                            answer: price, currency: currency, difficulty: difficulty,
                            payload: MoneyPayPayload(currency: currency, item: item(price: price), tray: currency.payTray(limit: limit)))
        case .moneyShopping:
            let count = age >= 8 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue ? 3 : 2
            let limit = shoppingLimit(age: age)
            let total = Int.random(in: count...limit)
            var remaining = total
            let pictures = emojis.shuffled()
            var items: [MoneyItem] = []
            for index in 0..<count {
                let price = index == count - 1 ? remaining : Int.random(in: 1...(remaining - (count - index - 1)))
                items.append(MoneyItem(emoji: pictures[index], price: price))
                remaining -= price
            }
            let choices = choices(answer: total, limit: limit, count: difficulty == .warmup ? 3 : 4, currency: currency,
                                  tempting: items.map(\.price))
            let prompt = count == 2
                ? L.t("How much for both?", no: "Hva koster begge?", es: "¿Cuánto cuestan los dos?", pt: "Quanto custam os dois?")
                : L.t("How much altogether?", no: "Hva koster alt?", es: "¿Cuánto cuesta todo?", pt: "Quanto custa tudo?")
            return exercise(kind, prompt: prompt, answer: total, currency: currency, difficulty: difficulty,
                            payload: MoneyShoppingPayload(currency: currency, items: items, choices: choices), choices: choices)
        case .moneyChange:
            let limit = changeLimit(age: age)
            let notes = currency.denominations.filter { $0.form == .note && $0.value <= limit && $0.value > 1 }
            let note = (difficulty == .warmup ? notes.first : notes.randomElement()) ?? MoneyDenomination(value: 10, form: .note)
            let price = Int.random(in: 1..<note.value)
            let change = note.value - price
            let choices = choices(answer: change, limit: note.value, count: difficulty == .warmup ? 3 : 4,
                                  currency: currency, tempting: [price, note.value])
            return exercise(kind, prompt: L.t("How much change?", no: "Hvor mye får du igjen?", es: "¿Cuánto te devuelven?", pt: "Quanto recebes de troco?"),
                            answer: change, currency: currency, difficulty: difficulty,
                            payload: MoneyChangePayload(currency: currency, item: item(price: price), note: note, choices: choices), choices: choices)
        default:
            // GameFactory only routes money kinds here; anything else plays the shopping game
            return make(.moneyShopping, age: age, difficulty: difficulty, currency: currency)
        }
    }

    static func payLimit(age: Int) -> Int { age <= 6 ? 10 : age == 7 ? 50 : 100 }
    static func shoppingLimit(age: Int) -> Int { age <= 7 ? 20 : age == 8 ? 50 : 100 }
    static func changeLimit(age: Int) -> Int { age <= 8 ? 50 : 100 }

    private static let emojis = ["🧸", "🍦", "⚽️", "🪁", "🚗", "🍎", "🎨", "📚"]

    private static func item(price: Int) -> MoneyItem {
        MoneyItem(emoji: emojis.randomElement()!, price: price)
    }

    private static func choices(answer: Int, limit: Int, count: Int, currency: MoneyCurrency, tempting: [Int]) -> [GameChoice] {
        var values = [answer]
        let candidates = (tempting + [answer - 1, answer + 1, answer - 2, answer + 2]).shuffled() + Array(0...limit).shuffled()
        for value in candidates where value >= 0 && value <= limit && !values.contains(value) {
            values.append(value)
            if values.count == count { break }
        }
        return values.shuffled().map { GameChoice(label: currency.format($0), value: $0) }
    }

    private static func exercise(_ kind: GameKind, prompt: String, answer: Int, currency: MoneyCurrency,
                                 difficulty: ExerciseDifficulty, payload: any GamePayload, choices: [GameChoice] = []) -> Exercise {
        Exercise(game: GameSpec(kind: kind, prompt: prompt, answerText: currency.format(answer), payload: payload),
                 correctAnswer: answer, options: choices.map(\.value), difficulty: difficulty)
    }
}

struct MoneyGameView: View {
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? MoneyPayPayload {
            MoneyPayView(spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        } else if let payload = spec.payload as? MoneyShoppingPayload {
            MoneyShoppingView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        } else if let payload = spec.payload as? MoneyChangePayload {
            MoneyChangeView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        }
    }
}
