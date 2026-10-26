import Foundation
import Testing
@testable import Geni

@MainActor
@Suite(.serialized)
struct MoneyTests {
    private let kinds: [GameKind] = [.moneyPay, .moneyShopping, .moneyChange]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private let currencies = [
        MoneyCurrency(code: "NOK", countryCode: "NO"), MoneyCurrency(code: "SEK", countryCode: "SE"),
        MoneyCurrency(code: "DKK", countryCode: "DK"), MoneyCurrency(code: "EUR", countryCode: "DE"),
        MoneyCurrency(code: "GBP", countryCode: "GB"), MoneyCurrency(code: "USD", countryCode: "US"),
        MoneyCurrency(code: "BRL", countryCode: "BR"), MoneyCurrency(code: "MXN", countryCode: "MX"),
        MoneyCurrency(code: "CHF", countryCode: "CH"), MoneyCurrency(code: "AUD", countryCode: "AU"),
        MoneyCurrency(code: "CAD", countryCode: "CA"), MoneyCurrency(code: "XYZ", countryCode: "ZZ")
    ]

    @Test func generationAcrossAgesDifficultiesAndCurrencies() throws {
        for kind in kinds {
            for age in kind.ages {
                for difficulty in difficulties {
                    // 100 per kind × age × difficulty; rotate through every supported currency.
                    for sample in 0..<100 {
                        let currency = currencies[sample % currencies.count]
                        let exercise = MoneyGames.make(kind, age: age, difficulty: difficulty, currency: currency)
                        let spec = try #require(exercise.game)
                        #expect(exercise.format == .game)
                        #expect(spec.kind == kind)
                        #expect(exercise.difficulty == difficulty)
                        #expect(!spec.prompt.isEmpty)
                        #expect(spec.answerText == currency.format(exercise.correctAnswer))
                        #expect(!spec.answerText.isEmpty)
                        #expect(Set(exercise.options).count == exercise.options.count)
                        #expect(exercise.options.count <= 4)

                        switch kind {
                        case .moneyPay:
                            let payload = try #require(spec.payload as? MoneyPayPayload)
                            #expect(payload.currency == currency)
                            #expect(exercise.options.isEmpty)
                            #expect((1...MoneyGames.payLimit(age: age)).contains(payload.item.price))
                            #expect(payload.item.price == exercise.correctAnswer)
                            #expect(!payload.item.emoji.isEmpty)
                            #expect((2...4).contains(payload.tray.count))
                            #expect(payload.tray.allSatisfy { currency.denominations.contains($0) })
                            if age == 6 { #expect(payload.tray.allSatisfy { $0.value <= 5 }) }
                            let pieces = currency.pieces(for: payload.item.price, using: payload.tray)
                            #expect(pieces.reduce(0) { $0 + $1.value } == payload.item.price)
                            #expect(pieces.count <= MoneyCounter.capacity)
                        case .moneyShopping:
                            let payload = try #require(spec.payload as? MoneyShoppingPayload)
                            #expect(payload.currency == currency)
                            #expect(payload.items.count == (age >= 8 && difficulty.rawValue >= 2 ? 3 : 2))
                            #expect(Set(payload.items.map(\.emoji)).count == payload.items.count)
                            #expect(payload.items.allSatisfy { $0.price > 0 })
                            #expect(payload.items.reduce(0) { $0 + $1.price } == exercise.correctAnswer)
                            #expect(exercise.correctAnswer <= MoneyGames.shoppingLimit(age: age))
                            checkChoices(payload.choices, exercise: exercise, currency: currency, limit: MoneyGames.shoppingLimit(age: age))
                        case .moneyChange:
                            let payload = try #require(spec.payload as? MoneyChangePayload)
                            #expect(payload.currency == currency)
                            #expect(payload.note.form == .note)
                            #expect(currency.denominations.contains(payload.note))
                            #expect(payload.note.value <= MoneyGames.changeLimit(age: age))
                            #expect((1..<payload.note.value).contains(payload.item.price))
                            #expect(payload.note.value - payload.item.price == exercise.correctAnswer)
                            checkChoices(payload.choices, exercise: exercise, currency: currency, limit: payload.note.value)
                        default: Issue.record("Unexpected Money game")
                        }
                    }
                }
            }
        }
    }

    private func checkChoices(_ choices: [GameChoice], exercise: Exercise, currency: MoneyCurrency, limit: Int) {
        #expect((3...4).contains(choices.count))
        #expect(choices.map(\.value) == exercise.options)
        #expect(exercise.options.contains(exercise.correctAnswer))
        #expect(Set(choices.map(\.label)).count == choices.count)
        #expect(choices.allSatisfy { (0...limit).contains($0.value) && $0.label == currency.format($0.value) })
    }

    @Test func everyPayPriceFitsOnTheCounter() {
        for currency in currencies {
            for age in GameKind.moneyPay.ages {
                let limit = MoneyGames.payLimit(age: age)
                let tray = currency.payTray(limit: limit)
                for price in 1...limit {
                    let pieces = currency.pieces(for: price, using: tray)
                    var counter = MoneyCounter()
                    for piece in pieces { counter.add(piece) }
                    #expect(counter.total == price, "\(currency.code), age \(age), price \(price)")
                    #expect(counter.pieces.count == pieces.count)
                }
            }
        }
    }

    @Test func counterAddsRemovesAndAllowsCorrections() {
        let currency = MoneyCurrency(code: "NOK", countryCode: "NO")
        let one = MoneyDenomination(value: 1, form: .coin)
        let five = MoneyDenomination(value: 5, form: .coin)
        var counter = MoneyCounter()
        #expect(counter.total == 0)
        counter.add(five)
        counter.add(one)
        counter.add(one)
        #expect(counter.total == 7)
        counter.remove(at: 1)
        #expect(counter.total == 6)
        #expect(counter.pieces == [five, one])
        counter.remove(at: 0)
        counter.add(five)
        #expect(counter.total == 6)
        counter.remove(at: 99)
        counter.remove(at: -1)
        #expect(counter.total == 6)
        for _ in 0..<MoneyCounter.capacity { counter.add(one) }
        #expect(counter.pieces.count == MoneyCounter.capacity)
        let fullTotal = counter.total
        counter.add(five)
        #expect(counter.total == fullTotal)
        while !counter.pieces.isEmpty { counter.remove(at: 0) }
        for piece in currency.pieces(for: 9, using: currency.payTray(limit: 10)) { counter.add(piece) }
        #expect(counter.total == 9)
    }

    @Test func denominationsMatchRealWholeUnitCash() {
        let expectedCoins: [String: [Int]] = [
            "NOK": [1, 5, 10, 20], "SEK": [1, 2, 5, 10], "DKK": [1, 2, 5, 10, 20],
            "EUR": [1, 2], "GBP": [1, 2], "USD": [], "BRL": [1], "MXN": [1, 2, 5, 10],
            "CHF": [1, 2, 5], "AUD": [1, 2], "CAD": [1, 2], "XYZ": [1, 2, 5]
        ]
        for currency in currencies {
            let denominations = currency.denominations
            #expect(denominations.filter { $0.form == .coin }.map(\.value) == expectedCoins[currency.code])
            #expect(denominations.allSatisfy { $0.value > 0 })
            #expect(Set(denominations.map(\.value)).count == denominations.count)
            #expect(denominations.contains { $0.form == .note && $0.value <= 50 && $0.value > 1 })
        }
        let dollars = MoneyCurrency(code: "USD", countryCode: "US").denominations
        #expect(dollars.contains(MoneyDenomination(value: 1, form: .note)))
        #expect(dollars.contains(MoneyDenomination(value: 5, form: .note)))
        #expect(MoneyCurrency(code: "XYZ", countryCode: "ZZ").denominations.map(\.value) == [1, 2, 5, 10, 20, 50, 100])
    }

    @Test func formattingUsesStorefrontPlacementAndWholeUnits() {
        #expect(MoneyCurrency(code: "USD", countryCode: "US").format(5) == "$5")
        #expect(MoneyCurrency(code: "GBP", countryCode: "GB").format(5) == "£5")
        #expect(MoneyCurrency(code: "NOK", countryCode: "NO").format(20).replacingOccurrences(of: "\u{00a0}", with: " ") == "20 kr")
        let euros = MoneyCurrency(code: "EUR", countryCode: "DE").format(2)
        #expect(euros.contains("€"))
        #expect(!euros.contains(","))
        for currency in currencies {
            let formatter = NumberFormatter()
            formatter.locale = currency.locale
            formatter.numberStyle = .currency
            formatter.currencyCode = currency.code
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            for value in [0, 1, 2, 5, 20, 100] {
                #expect(currency.format(value) == formatter.string(from: NSNumber(value: value)))
            }
        }
    }

    @Test func everyLanguageHasQuestionsAndFormattedAnswers() throws {
        let key = "geni_app_language"
        let saved = UserDefaults.standard.string(forKey: key)
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            for kind in kinds {
                for difficulty in difficulties {
                    for age in kind.ages {
                        let exercise = MoneyGames.make(kind, age: age, difficulty: difficulty)
                        let spec = try #require(exercise.game)
                        #expect(!spec.prompt.isEmpty)
                        #expect(!spec.answerText.isEmpty)
                        #expect(spec.answerText == MoneyCurrency.storefront.format(exercise.correctAnswer))
                    }
                }
            }
        }
    }

    @Test func storefrontFactoryUsesSharedRegion() throws {
        for kind in kinds {
            let exercise = MoneyGames.make(kind, age: kind.ages.lowerBound, difficulty: .normal)
            let payload = try #require(exercise.game?.payload)
            let currency: MoneyCurrency?
            switch payload {
            case let pay as MoneyPayPayload: currency = pay.currency
            case let shopping as MoneyShoppingPayload: currency = shopping.currency
            case let change as MoneyChangePayload: currency = change.currency
            default: currency = nil
            }
            #expect(currency?.code == StoreRegion.currencyCode)
            #expect(currency?.countryCode == StoreRegion.countryCode)
        }
    }

    @Test func correctChoiceMovesBetweenPositions() throws {
        for kind in [GameKind.moneyShopping, .moneyChange] {
            var positions = Set<Int>()
            for _ in 0..<100 {
                let exercise = MoneyGames.make(kind, age: 9, difficulty: .normal)
                positions.insert(try #require(exercise.options.firstIndex(of: exercise.correctAnswer)))
            }
            #expect(positions.count > 1)
        }
    }
}
