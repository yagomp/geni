import Foundation

// Number sense for 1st–2nd grade: ten friends (tiervenner), doubles, number neighbours,
// counting down and skip counting. Every game is a picture plus 2–4 number tiles.

// MARK: - Payloads

/// A 2×5 ten-frame with `filled` pictures; optionally the same sum written out ("7 + ? = 10").
nonisolated struct TenFramePayload: GamePayload {
    let filled: Int
    let emoji: String
    let showsFrame: Bool
    /// Tokens drawn as tiles, e.g. ["7", "+", "?", "=", "10"]. Empty when only the frame shows.
    let equation: [String]
    let choices: [GameChoice]
}

nonisolated enum DoublesPicture: Sendable, CaseIterable {
    case dice, domino, ladybird
}

/// Two mirrored halves (two dice, a domino, ladybird wings) with `left` and `right` dots.
nonisolated struct DoublesPayload: GamePayload {
    let left: Int
    let right: Int
    let picture: DoublesPicture
    /// 0 pink, 1 orange, 2 yellow — the ladybird's wings.
    let tint: Int
    let equation: [String]
    let choices: [GameChoice]
}

nonisolated enum NumberTrackStyle: Sendable {
    /// A street of numbered houses.
    case houses
    /// Countdown bubbles leading to a rocket.
    case countdown
}

/// A row of numbers with one gap (`nil`).
nonisolated struct NumberTrackPayload: GamePayload {
    let numbers: [Int?]
    let style: NumberTrackStyle
    let choices: [GameChoice]
}

/// A frog hopping along a number line by `step` (negative = backwards); one stop is `nil`.
nonisolated struct FrogHopPayload: GamePayload {
    let numbers: [Int?]
    let step: Int
    let choices: [GameChoice]
}

// MARK: - Generators

enum NumberSenseGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .tenFriends: return tenFriends(age: age, difficulty: difficulty)
        case .doubles: return doubles(age: age, difficulty: difficulty)
        case .numberNeighbours: return numberNeighbours(age: age, difficulty: difficulty)
        case .countBackwards: return countBackwards(age: age, difficulty: difficulty)
        default: return skipCounting(age: age, difficulty: difficulty)
        }
    }

    // MARK: Ten friends

    static let frameEmoji = ["🍎", "⭐", "🐞", "🍓", "⚽", "🐟", "🌸", "🧁", "🐣", "🍪"]

    static func tenFriends(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let filledRange: ClosedRange<Int>
        switch (min(age, 7), difficulty) {
        case (...5, .warmup): filledRange = 6...9
        case (...5, .normal): filledRange = 5...9
        case (...5, .harder): filledRange = 3...9
        case (6, .warmup): filledRange = 5...9
        case (6, .normal): filledRange = 3...9
        default: filledRange = 1...9
        }
        let filled = Int.random(in: filledRange)
        let answer = 10 - filled

        // Age 5 and easy age 6 see only the frame; then the sum joins it; age 7 at the top is numbers only.
        let showsFrame = age < 7 || difficulty.rawValue <= ExerciseDifficulty.normal.rawValue
        let showsSum = age >= 7 || (age == 6 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue)
        var equation: [String] = []
        if showsSum {
            let flipped = age >= 7 && difficulty == .challenge && Bool.random()
            equation = flipped ? ["?", "+", "\(filled)", "=", "10"] : ["\(filled)", "+", "?", "=", "10"]
        }

        let choices = numberChoices(answer: answer,
                                    preferred: [answer - 1, answer + 1, filled, answer + 2, answer - 2],
                                    count: age <= 5 ? 3 : 4, range: 1...10)
        let prompt = L.t("How many more to make 10?", no: "Hvor mange mangler til 10?",
                         es: "¿Cuántos faltan para 10?", pt: "Quantos faltam para 10?")
        let payload = TenFramePayload(filled: filled, emoji: frameEmoji.randomElement()!, showsFrame: showsFrame,
                                      equation: equation, choices: choices)
        return exercise(.tenFriends, prompt: prompt, answer: answer, payload: payload, choices: choices, difficulty: difficulty)
    }

    // MARK: Doubles

    static func doubles(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        var left: Int
        var right: Int
        if age <= 6 {
            let range: ClosedRange<Int> = switch difficulty {
            case .warmup: 1...3
            case .normal: 1...5
            case .harder: 2...5
            case .challenge: 3...5
            }
            left = Int.random(in: range)
            right = left
        } else if difficulty == .challenge {
            // Near doubles: 5 + 6 is double 5 and one more.
            left = Int.random(in: 3...9)
            right = left + 1
            if Bool.random() { swap(&left, &right) }
        } else {
            let range: ClosedRange<Int> = switch difficulty {
            case .warmup: 2...5
            case .normal: 3...7
            default: 5...10
            }
            left = Int.random(in: range)
            right = left
        }
        let answer = left + right
        let picture: DoublesPicture = max(left, right) <= 6 ? DoublesPicture.allCases.randomElement()! : .ladybird
        let equation = age >= 7 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue
            ? ["\(left)", "+", "\(right)", "=", "?"] : []
        let choices = numberChoices(answer: answer,
                                    preferred: [answer + 1, answer - 1, answer + 2, answer - 2, max(left, right)],
                                    count: age <= 6 && difficulty == .warmup ? 3 : 4, range: 1...20)
        let prompt = L.t("How many in all?", no: "Hvor mange til sammen?",
                         es: "¿Cuántos hay en total?", pt: "Quantos são ao todo?")
        let payload = DoublesPayload(left: left, right: right, picture: picture, tint: Int.random(in: 0...2),
                                     equation: equation, choices: choices)
        return exercise(.doubles, prompt: prompt, answer: answer, payload: payload, choices: choices, difficulty: difficulty)
    }

    // MARK: Number neighbours

    private enum Gap { case next, before, middle }

    static func numberNeighbours(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let top = age <= 5 ? 10 : 20
        let gap: Gap
        let houses: Int
        switch difficulty {
        case .warmup: gap = .next; houses = 5
        case .normal: gap = [.next, .before].randomElement()!; houses = 5
        case .harder: gap = [.next, .before, .middle].randomElement()!; houses = 4
        case .challenge: gap = [.before, .middle].randomElement()!; houses = 3
        }
        // Age 6 practises the teens once warmed up.
        let lowest = age >= 6 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue ? 8 : 1
        let highest = age >= 6 && difficulty == .warmup ? 12 : top
        let start = Int.random(in: lowest...(highest - houses + 1))
        let missing = switch gap {
        case .next: houses - 1
        case .before: 0
        case .middle: Int.random(in: 1...(houses - 2))
        }
        let answer = start + missing
        let numbers: [Int?] = (0..<houses).map { $0 == missing ? nil : start + $0 }

        let choices = numberChoices(answer: answer,
                                    preferred: [answer + 1, answer - 1, answer + 2, answer - 2, answer + 10],
                                    count: age <= 5 || difficulty == .warmup ? 3 : 4, range: 1...top)
        let prompt = switch gap {
        case .next: L.t("Which number comes next?", no: "Hvilket tall kommer etter?",
                        es: "¿Qué número va después?", pt: "Que número vem a seguir?")
        case .before: L.t("Which number comes before?", no: "Hvilket tall kommer før?",
                          es: "¿Qué número va antes?", pt: "Que número vem antes?")
        case .middle: missingPrompt
        }
        let payload = NumberTrackPayload(numbers: numbers, style: .houses, choices: choices)
        return exercise(.numberNeighbours, prompt: prompt, answer: answer, payload: payload, choices: choices, difficulty: difficulty)
    }

    // MARK: Count backwards

    static func countBackwards(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let start: Int
        var middle = false
        switch difficulty {
        case .warmup: start = Int.random(in: 5...10)
        case .normal: start = Int.random(in: 3...10); middle = Bool.random()
        case .harder: start = Int.random(in: 11...20)
        case .challenge:
            middle = Bool.random()
            // Through ten (12, 11, 10, 9) or a gap high up.
            start = middle ? Int.random(in: 12...20) : Int.random(in: 11...13)
        }
        let missing = middle ? Int.random(in: 1...2) : 3
        let answer = start - missing
        let numbers: [Int?] = (0..<4).map { $0 == missing ? nil : start - $0 }
        let choices = numberChoices(answer: answer,
                                    preferred: [answer + 1, answer - 1, answer + 2, answer - 2],
                                    count: difficulty == .warmup ? 3 : 4, range: 0...20)
        let prompt = middle ? missingPrompt : nextPrompt
        let payload = NumberTrackPayload(numbers: numbers, style: .countdown, choices: choices)
        return exercise(.countBackwards, prompt: prompt, answer: answer, payload: payload, choices: choices, difficulty: difficulty)
    }

    // MARK: Skip counting

    static func skipCounting(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let stops = 5
        var step: Int
        var start: Int
        var backwards = false
        var middle = false
        if age <= 7 {
            switch difficulty {
            case .warmup:
                step = [2, 10].randomElement()!
                start = step * Int.random(in: 0...1)
            case .normal:
                step = [2, 10].randomElement()!
                start = step == 2 ? 2 * Int.random(in: 0...10) : 10 * Int.random(in: 0...5)
            case .harder:
                step = [5, 5, 2].randomElement()!
                start = step == 5 ? 5 * Int.random(in: 0...6) : 2 * Int.random(in: 5...15)
            case .challenge:
                step = [2, 10].randomElement()!
                backwards = true
                start = step == 2 ? 2 * Int.random(in: 5...15) : 10 * Int.random(in: 5...10)
            }
        } else {
            step = [2, 5, 10].randomElement()!
            switch difficulty {
            case .warmup:
                start = step * Int.random(in: 0...2)
            case .normal:
                start = step * Int.random(in: 0...((100 - 4 * step) / step))
            case .harder:
                backwards = true
                start = step * Int.random(in: 4...(100 / step))
            case .challenge:
                // Off the usual track: 10s from 3 (3, 13, 23 …) or 2s from an odd number.
                step = [2, 10].randomElement()!
                backwards = Bool.random()
                middle = Bool.random()
                let offset = step == 10 ? Int.random(in: 1...9) : 1
                start = backwards
                    ? step * Int.random(in: 4...((100 - offset) / step)) + offset
                    : step * Int.random(in: 0...((100 - offset) / step - 4)) + offset
            }
        }
        let signed = backwards ? -step : step
        let missing = middle ? Int.random(in: 1...3) : stops - 1
        let answer = start + signed * missing
        let numbers: [Int?] = (0..<stops).map { $0 == missing ? nil : start + signed * $0 }
        let choices = numberChoices(answer: answer,
                                    preferred: [answer + 1, answer - 1, answer + signed, answer + signed * 2, answer + 10],
                                    count: 4, range: 0...100)
        let prompt = middle ? missingPrompt : nextPrompt
        let payload = FrogHopPayload(numbers: numbers, step: signed, choices: choices)
        return exercise(.skipCounting, prompt: prompt, answer: answer, payload: payload, choices: choices, difficulty: difficulty)
    }

    // MARK: Helpers

    private static var nextPrompt: String {
        L.t("What comes next?", no: "Hva kommer så?", es: "¿Qué número sigue?", pt: "Que número vem a seguir?")
    }

    private static var missingPrompt: String {
        L.t("Which number is missing?", no: "Hvilket tall mangler?", es: "¿Qué número falta?", pt: "Que número falta?")
    }

    /// The answer plus the likeliest slips (off by one, the number already shown), shuffled.
    static func numberChoices(answer: Int, preferred: [Int], count: Int, range: ClosedRange<Int>) -> [GameChoice] {
        var values = [answer]
        for value in preferred where range.contains(value) && !values.contains(value) && values.count < count {
            values.append(value)
        }
        // Small answers near the edge of the range: fill with the nearest free numbers.
        var distance = 1
        while values.count < count && distance <= range.count {
            for value in [answer + distance, answer - distance] where range.contains(value) && !values.contains(value) && values.count < count {
                values.append(value)
            }
            distance += 1
        }
        return values.shuffled().map { GameChoice(label: "\($0)", value: $0) }
    }

    private static func exercise(_ kind: GameKind, prompt: String, answer: Int, payload: any GamePayload,
                                 choices: [GameChoice], difficulty: ExerciseDifficulty) -> Exercise {
        Exercise(game: GameSpec(kind: kind, prompt: prompt, answerText: "\(answer)", payload: payload),
                 correctAnswer: answer, options: choices.map(\.value), difficulty: difficulty)
    }
}
