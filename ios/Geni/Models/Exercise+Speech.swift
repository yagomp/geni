import Foundation

/// What a 4–5-year-old hears when an exercise appears: the on-screen question, with sums read as words.
extension Exercise {
    var spokenPrompt: String? {
        switch format {
        case .game:
            return game?.prompt
        case .countingObjects, .tenFrame:
            return L.s(.howMany)
        case .compareGroups:
            return L.s(.whichHasMore)
        case .visualAddition:
            return shouldShowEmojiCounting ? L.s(.howManyTotal) : whatIs(spoken(operand1, operation, operand2))
        case .visualSubtraction:
            return "\(spoken(operand1, operation, operand2)). \(L.s(.spokenHowManyLeft))"
        case .solveResult:
            return whatIs(spoken(operand1, operation, operand2))
        case .missingNumber:
            let blank = L.s(.spokenBlank)
            let lhs = missingOperandIndex == 0
                ? "\(blank) \(Self.word(for: operation)) \(operand2)"
                : "\(operand1) \(Self.word(for: operation)) \(blank)"
            return Self.question("\(lhs) \(L.s(.spokenIs)) \(correctAnswer)")
        case .trueFalse:
            let claim = "\(spoken(operand1, operation, operand2)) \(L.s(.spokenIs)) \(proposedAnswer ?? correctAnswer)"
            return String(format: L.s(.spokenTrueOrFalse), claim)
        default:
            return nil
        }
    }

    private func spoken(_ lhs: Int, _ operation: MathOperation, _ rhs: Int) -> String {
        "\(lhs) \(Self.word(for: operation)) \(rhs)"
    }

    private func whatIs(_ expression: String) -> String {
        String(format: L.s(.spokenWhatIs), expression)
    }

    /// "what plus 2 is 5" → the language's question form, reusing the "What is %@?" punctuation.
    private static func question(_ text: String) -> String {
        let template = L.s(.spokenWhatIs)
        let prefix = template.hasPrefix("\u{00BF}") ? "\u{00BF}" : ""
        let capitalized = text.prefix(1).uppercased() + text.dropFirst()
        return "\(prefix)\(capitalized)?"
    }

    static func word(for operation: MathOperation) -> String {
        switch operation {
        case .addition: return L.s(.spokenPlus)
        case .subtraction: return L.s(.spokenMinus)
        case .multiplication: return L.s(.spokenTimes)
        case .division: return L.s(.spokenDividedBy)
        }
    }
}
