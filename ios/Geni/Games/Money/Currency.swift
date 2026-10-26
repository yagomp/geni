import Foundation

nonisolated struct MoneyDenomination: Sendable, Equatable, Hashable {
    enum Form: Sendable, Hashable { case coin, note }
    let value: Int
    let form: Form
}

nonisolated struct MoneyCurrency: Sendable, Equatable {
    let code: String
    let countryCode: String

    static var storefront: MoneyCurrency {
        MoneyCurrency(code: StoreRegion.currencyCode, countryCode: StoreRegion.countryCode)
    }

    var locale: Locale {
        // Resolve the territory's language: und_NO alone gives "NOK 20", rather than "20 kr".
        Locale(identifier: Locale.Language(identifier: "und_\(countryCode)").maximalIdentifier)
    }

    func format(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(code)"
    }

    /// Whole-unit cash in everyday use; fractional coins are deliberately omitted.
    var denominations: [MoneyDenomination] {
        let coins: [Int]
        let notes: [Int]
        switch code {
        case "NOK": (coins, notes) = ([1, 5, 10, 20], [50, 100])
        case "SEK": (coins, notes) = ([1, 2, 5, 10], [20, 50, 100])
        case "DKK": (coins, notes) = ([1, 2, 5, 10, 20], [50, 100])
        case "EUR": (coins, notes) = ([1, 2], [5, 10, 20, 50, 100])
        case "GBP": (coins, notes) = ([1, 2], [5, 10, 20, 50])
        case "USD": (coins, notes) = ([], [1, 5, 10, 20, 50, 100])
        case "BRL": (coins, notes) = ([1], [2, 5, 10, 20, 50, 100])
        case "MXN": (coins, notes) = ([1, 2, 5, 10], [20, 50, 100])
        case "CHF": (coins, notes) = ([1, 2, 5], [10, 20, 50, 100])
        case "AUD", "CAD": (coins, notes) = ([1, 2], [5, 10, 20, 50, 100])
        default: (coins, notes) = ([1, 2, 5], [10, 20, 50, 100])
        }
        return (coins.map { MoneyDenomination(value: $0, form: .coin) }
                + notes.map { MoneyDenomination(value: $0, form: .note) }).sorted { $0.value < $1.value }
    }

    /// Four big tray buttons at most, with small change and a larger amount for older children.
    func payTray(limit: Int) -> [MoneyDenomination] {
        let available = denominations.filter { $0.value <= (limit <= 10 ? 5 : limit) }
        guard available.count > 4 else { return available }
        var selected = Array(available.prefix(2))
        for denomination in [available.last(where: { $0.value <= 10 }), available.last(where: { $0.value <= limit / 2 })].compactMap({ $0 }) {
            if !selected.contains(denomination) { selected.append(denomination) }
        }
        return selected.sorted { $0.value < $1.value }
    }

    func pieces(for amount: Int, using tray: [MoneyDenomination]) -> [MoneyDenomination] {
        guard amount > 0 else { return [] }
        var remaining = amount
        var pieces: [MoneyDenomination] = []
        for denomination in tray.sorted(by: { $0.value > $1.value }) {
            while remaining >= denomination.value {
                pieces.append(denomination)
                remaining -= denomination.value
            }
        }
        return pieces
    }
}

/// Visible pieces remain the source of truth, including after an incorrect first attempt.
nonisolated struct MoneyCounter {
    static let capacity = 10
    private(set) var pieces: [MoneyDenomination] = []
    var total: Int { pieces.reduce(0) { $0 + $1.value } }

    mutating func add(_ denomination: MoneyDenomination) {
        guard pieces.count < Self.capacity else { return }
        pieces.append(denomination)
    }

    mutating func remove(at index: Int) {
        guard pieces.indices.contains(index) else { return }
        pieces.remove(at: index)
    }
}
