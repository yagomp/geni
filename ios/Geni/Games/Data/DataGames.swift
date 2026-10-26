import SwiftUI

// Data games, ages 7–10: read a tally chart, read a bar chart, estimate.

nonisolated struct TallyRow: Sendable, Equatable {
    let emoji: String
    let count: Int
}

/// Three rows of emoji + tally marks. `choices` are emoji (value = row index) or vote counts.
nonisolated struct TallyPayload: GamePayload {
    let rows: [TallyRow]
    let choices: [GameChoice]
}

nonisolated struct BarItem: Sendable, Equatable {
    let emoji: String
    let value: Int
}

/// A vertical bar chart. `choices` are emoji (value = bar index) or numbers.
nonisolated struct BarPayload: GamePayload {
    let bars: [BarItem]
    let axisMax: Int
    let choices: [GameChoice]
}

/// A bean in the jar, in cell units from the jar's bottom-left corner (8 cells across).
nonisolated struct JarBean: Sendable, Equatable {
    let x: Double
    let y: Double
    let tone: Int
}

/// Either a sum to round (`expression`) or a jar of beans (`beans`).
nonisolated struct EstimatePayload: GamePayload {
    static let jarColumns = 8
    let expression: String?
    let beans: [JarBean]
    let choices: [GameChoice]
}

enum DataGames {
    private static let fruits = ["🍎", "🍌", "🍇", "🍓", "🍊", "🍉"]
    private static let animals = ["🐶", "🐱", "🐰", "🐸", "🐵", "🐼"]

    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .barChart: return barChart(age: age, difficulty: difficulty)
        case .estimate: return estimate(age: age, difficulty: difficulty)
        default: return tallyChart(age: age, difficulty: difficulty)
        }
    }

    private static func emojis(_ count: Int) -> [String] {
        Array((Bool.random() ? fruits : animals).shuffled().prefix(count))
    }

    /// `count` distinct values in `range` whose top two differ by at least `minGap`.
    private static func distinctValues(_ count: Int, in range: ClosedRange<Int>, minGap: Int) -> [Int] {
        while true {
            let values = Array(range.shuffled().prefix(count))
            let top = values.sorted(by: >)
            if top[0] - top[1] >= minGap { return values }
        }
    }

    /// The right number plus the nearest wrong ones, shuffled.
    private static func numberChoices(correct: Int, in range: ClosedRange<Int>, total: Int) -> (choices: [GameChoice], correct: GameChoice) {
        let near = range.filter { $0 != correct }.shuffled().sorted { abs($0 - correct) < abs($1 - correct) }
        let wrong = Array(near.prefix(total + 1).shuffled().prefix(total - 1))
        let right = GameChoice(label: "\(correct)", value: correct)
        let choices = ([right] + wrong.map { GameChoice(label: "\($0)", value: $0) }).shuffled()
        return (choices, right)
    }

    // MARK: Tally chart

    private static func tallyChart(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let ceilings = age <= 7 ? [6, 9, 11, 12] : [10, 12, 14, 15]
        let maxCount = ceilings[min(max(difficulty.rawValue, 0), 3)]
        let counts = distinctValues(3, in: 1...maxCount, minGap: difficulty.rawValue <= 1 ? 2 : 1)
        let rows = zip(emojis(3), counts).map { TallyRow(emoji: $0, count: $1) }

        let mostVotes = Double.random(in: 0..<1) < (age <= 7 ? 0.6 : 0.4)
        if mostVotes {
            let winner = counts.firstIndex(of: counts.max() ?? 0) ?? 0
            let choices = rows.indices.map { GameChoice(label: rows[$0].emoji, value: $0) }.shuffled()
            let correct = GameChoice(label: rows[winner].emoji, value: winner)
            let prompt = L.t("Which got the most votes?", no: "Hvilken fikk flest stemmer?",
                             es: "¿Cuál tiene más votos?", pt: "Qual teve mais votos?")
            return makeTally(rows, prompt: prompt, choices: choices, correct: correct, difficulty: difficulty)
        }
        let row = rows.randomElement() ?? rows[0]
        let picked = numberChoices(correct: row.count, in: 1...15, total: difficulty.rawValue <= 1 ? 3 : 4)
        let e = row.emoji
        let prompt = L.t("How many votes did \(e) get?", no: "Hvor mange stemmer fikk \(e)?",
                         es: "¿Cuántos votos tiene \(e)?", pt: "Quantos votos teve \(e)?")
        return makeTally(rows, prompt: prompt, choices: picked.choices, correct: picked.correct, difficulty: difficulty)
    }

    private static func makeTally(_ rows: [TallyRow], prompt: String, choices: [GameChoice],
                                  correct: GameChoice, difficulty: ExerciseDifficulty) -> Exercise {
        Exercise(game: GameSpec(kind: .tallyChart, prompt: prompt, answerText: correct.label,
                                payload: TallyPayload(rows: rows, choices: choices)),
                 correctAnswer: correct.value, options: choices.map(\.value), difficulty: difficulty)
    }

    // MARK: Bar chart

    private enum BarQuestion { case tallest, count, difference }

    private static func barChart(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let n = age <= 7 ? 3 : (age == 8 ? Int.random(in: 3...4) : 4)
        let axisMax = age <= 7 ? 6 : (age == 8 ? 8 : 10)
        let values = distinctValues(n, in: 1...axisMax, minGap: difficulty.rawValue <= 1 ? 2 : 1)
        let items = zip(emojis(n), values).map { BarItem(emoji: $0, value: $1) }
        let level = difficulty.rawValue

        let questions: [BarQuestion]
        switch (age <= 7, level) {
        case (_, 0): questions = [.tallest, .count]
        case (true, _): questions = level == 1 ? [.tallest, .count] : [.count, .tallest]
        case (false, 1): questions = [.tallest, .count, .difference]
        default: questions = [.difference, .count, .difference]
        }

        let choices: [GameChoice]
        let correct: GameChoice
        let prompt: String
        switch questions.randomElement() ?? .count {
        case .tallest:
            let winner = values.firstIndex(of: values.max() ?? 0) ?? 0
            choices = items.indices.map { GameChoice(label: items[$0].emoji, value: $0) }.shuffled()
            correct = GameChoice(label: items[winner].emoji, value: winner)
            prompt = L.t("Which is the tallest?", no: "Hvilken er høyest?",
                         es: "¿Cuál es la más alta?", pt: "Qual é a mais alta?")
        case .count:
            let item = items.randomElement() ?? items[0]
            let picked = numberChoices(correct: item.value, in: 1...axisMax, total: level <= 1 ? 3 : 4)
            choices = picked.choices
            correct = picked.correct
            let e = item.emoji
            prompt = L.t("How many \(e)?", no: "Hvor mange \(e)?", es: "¿Cuántos \(e)?", pt: "Quantos \(e)?")
        case .difference:
            let pair = items.shuffled().prefix(2).sorted { $0.value > $1.value }
            let picked = numberChoices(correct: pair[0].value - pair[1].value, in: 1...(axisMax - 1), total: 4)
            choices = picked.choices
            correct = picked.correct
            let (more, less) = (pair[0].emoji, pair[1].emoji)
            prompt = L.t("How many more \(more) than \(less)?", no: "Hvor mange flere \(more) enn \(less)?",
                         es: "¿Cuántos \(more) más que \(less)?", pt: "Quantos mais \(more) do que \(less)?")
        }
        return Exercise(game: GameSpec(kind: .barChart, prompt: prompt, answerText: correct.label,
                                       payload: BarPayload(bars: items, axisMax: axisMax, choices: choices)),
                        correctAnswer: correct.value, options: choices.map(\.value), difficulty: difficulty)
    }

    // MARK: Estimate

    private static func estimate(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        Int.random(in: 0..<10) < 4 ? jar(difficulty: difficulty) : roundedSum(age: age, difficulty: difficulty)
    }

    /// "Which is closest to 98 + 103?" — tens for the younger/easier ones, hundreds for the older/harder.
    private static func roundedSum(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let level = difficulty.rawValue
        let hundreds = age >= 10 ? (level > 0 || Bool.random()) : (level >= 2 && Bool.random())
        let unit = hundreds ? 100 : 10
        let step = hundreds ? 100 : 20
        let noiseLimit = hundreds ? 5 : 2  // tens: ±4 total stays well inside the 20-step distractors
        func noise() -> Int { Int.random(in: 1...noiseLimit) * (Bool.random() ? 1 : -1) }

        let subtract = level >= 1 && Int.random(in: 0..<10) < 3
        let a: Int, b: Int, target: Int
        if subtract {
            let y = Int.random(in: 1...3)
            let x = y + Int.random(in: (hundreds ? 2 : 3)...(hundreds ? 5 : 6))
            (a, b, target) = (x * unit + noise(), y * unit + noise(), (x - y) * unit)
        } else {
            let range = hundreds ? 1...5 : 2...6
            let x = Int.random(in: range), y = Int.random(in: range)
            (a, b, target) = (x * unit + noise(), y * unit + noise(), (x + y) * unit)
        }

        let others = [target - step, target + step, target + 2 * step, target - 2 * step].filter { $0 > 0 }
        let total = level <= 1 ? 3 : 4
        let choices = ([target] + others.prefix(total - 1)).shuffled().map { GameChoice(label: "\($0)", value: $0) }
        let expression = "\(a) \(subtract ? "−" : "+") \(b)"
        let prompt = L.t("Which is closest to \(expression)?", no: "Hva er nærmest \(expression)?",
                         es: "¿Cuál se acerca más a \(expression)?", pt: "Qual é o mais próximo de \(expression)?")
        return Exercise(game: GameSpec(kind: .estimate, prompt: prompt, answerText: "\(target)",
                                       payload: EstimatePayload(expression: expression, beans: [], choices: choices)),
                        correctAnswer: target, options: choices.map(\.value), difficulty: difficulty)
    }

    /// A jar of 18–55 beans: "About how many?" with choices at least ~2× apart.
    private static func jar(difficulty: ExerciseDifficulty) -> Exercise {
        let target = [20, 30, 40, 50].randomElement() ?? 30
        let wrong: [Int: [Int]] = [20: [10, 50, 5], 30: [10, 100, 60], 40: [20, 100, 10], 50: [10, 100, 25]]
        let count = Int((Double(target) * Double.random(in: 0.9...1.1)).rounded())
        let total = difficulty.rawValue >= 2 ? 4 : 3
        let values = ([target] + (wrong[target] ?? []).prefix(total - 1)).shuffled()
        let choices = values.map { GameChoice(label: "\($0)", value: $0) }

        let columns = EstimatePayload.jarColumns
        var beans: [JarBean] = []
        let fullRows = count / columns
        var cells = (0..<fullRows).flatMap { row in (0..<columns).map { (row, $0) } }
        cells += Array((0..<columns).shuffled().prefix(count % columns)).map { (fullRows, $0) }
        for (index, cell) in cells.enumerated() {
            beans.append(JarBean(x: Double(cell.1) + 0.5 + Double.random(in: -0.1...0.1),
                                 y: Double(cell.0) + 0.5 + Double.random(in: -0.1...0.1),
                                 tone: index % 4))
        }
        let prompt = L.t("About how many?", no: "Omtrent hvor mange?", es: "¿Más o menos cuántas?", pt: "Cerca de quantas?")
        return Exercise(game: GameSpec(kind: .estimate, prompt: prompt, answerText: "\(target)",
                                       payload: EstimatePayload(expression: nil, beans: beans, choices: choices)),
                        correctAnswer: target, options: values, difficulty: difficulty)
    }
}
