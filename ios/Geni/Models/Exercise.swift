import Foundation

nonisolated enum ExerciseFormat: String, Codable, Sendable {
    case solveResult
    case missingNumber
    case trueFalse
    case comparison
    case countingObjects
    case visualAddition
    case compareGroups
    case tenFrame
    case matchConnect
    case numberBonds
    case diceAddition
    case evenOddSort
    case visualSubtraction
    case multiStep
    case numberSequence
    case areaPerimeter
    case fractionPick
    case longDivision
}

nonisolated struct Exercise: Identifiable, Sendable {
    let id: String
    let operand1: Int
    let operand2: Int
    let operation: MathOperation
    let correctAnswer: Int
    let options: [Int]
    let difficulty: ExerciseDifficulty
    let format: ExerciseFormat
    let missingOperandIndex: Int?
    let proposedAnswer: Int?
    let comparisonLeft: (Int, MathOperation, Int)?
    let comparisonRight: (Int, MathOperation, Int)?
    let emojiSymbol: String?
    let emojiSymbolRight: String?
    let matchLeftLabels: [String]?
    let matchRightLabels: [String]?
    let correctMatchIndices: [Int]?
    let numberBondMissingWhole: Bool?
    let sequenceNumbers: [Int]?
    let multiStepExpression: String?
    let gridWidth: Int?
    let gridHeight: Int?
    let fractionNumerator: Int?
    let fractionDenominator: Int?
    let divisionRemainder: Int?

    init(operand1: Int, operand2: Int, operation: MathOperation, difficulty: ExerciseDifficulty, format: ExerciseFormat = .solveResult) {
        self.id = UUID().uuidString
        self.operand1 = operand1
        self.operand2 = operand2
        self.operation = operation
        self.difficulty = difficulty
        self.format = format

        let answer: Int
        switch operation {
        case .addition: answer = operand1 + operand2
        case .subtraction: answer = operand1 - operand2
        case .multiplication: answer = operand1 * operand2
        case .division: answer = operand1 / operand2
        }
        self.correctAnswer = answer

        self.emojiSymbol = nil
        self.emojiSymbolRight = nil
        self.matchLeftLabels = nil
        self.matchRightLabels = nil
        self.correctMatchIndices = nil
        self.numberBondMissingWhole = nil
        self.sequenceNumbers = nil
        self.multiStepExpression = nil
        self.gridWidth = nil
        self.gridHeight = nil
        self.fractionNumerator = nil
        self.fractionDenominator = nil
        self.divisionRemainder = nil

        switch format {
        case .solveResult:
            self.missingOperandIndex = nil
            self.proposedAnswer = nil
            self.comparisonLeft = nil
            self.comparisonRight = nil

            var opts = Set<Int>()
            opts.insert(answer)
            var attempts = 0
            while opts.count < 4 && attempts < 50 {
                attempts += 1
                let offset = Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
                let wrong = answer + offset
                if wrong >= 0 && wrong != answer {
                    opts.insert(wrong)
                }
            }
            var fallback = answer + 6
            while opts.count < 4 { opts.insert(fallback); fallback += 1 }
            self.options = Array(opts).shuffled()

        case .missingNumber:
            let missingIdx = Bool.random() ? 0 : 1
            self.missingOperandIndex = missingIdx
            self.proposedAnswer = nil
            self.comparisonLeft = nil
            self.comparisonRight = nil

            let missingValue = missingIdx == 0 ? operand1 : operand2
            var opts = Set<Int>()
            opts.insert(missingValue)
            var attempts2 = 0
            while opts.count < 4 && attempts2 < 50 {
                attempts2 += 1
                let offset = Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
                let wrong = missingValue + offset
                if wrong >= 0 && wrong != missingValue {
                    opts.insert(wrong)
                }
            }
            var fallback2 = missingValue + 6
            while opts.count < 4 { opts.insert(fallback2); fallback2 += 1 }
            self.options = Array(opts).shuffled()

        case .trueFalse:
            self.missingOperandIndex = nil
            self.comparisonLeft = nil
            self.comparisonRight = nil

            let isCorrectProposal = Bool.random()
            if isCorrectProposal {
                self.proposedAnswer = answer
            } else {
                let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
                let wrong = answer + offset
                self.proposedAnswer = wrong >= 0 ? wrong : answer + abs(offset)
            }
            self.options = [1, 0]

        case .comparison:
            self.missingOperandIndex = nil
            self.proposedAnswer = nil
            self.comparisonLeft = (operand1, operation, operand2)

            let rightAnswer = answer + Int.random(in: -3...3)
            let safeRight = max(rightAnswer, 0)
            let rOp2 = max(Int.random(in: 1...max(operand2, 2)), 1)
            let rOp1: Int
            switch operation {
            case .addition: rOp1 = safeRight - rOp2
            case .subtraction: rOp1 = safeRight + rOp2
            case .multiplication: rOp1 = rOp2 > 0 ? safeRight / max(rOp2, 1) : safeRight
            case .division: rOp1 = safeRight * max(rOp2, 1)
            }
            let safeROp1 = max(rOp1, 0)
            self.comparisonRight = (safeROp1, operation, rOp2)

            let leftVal = answer
            let rightVal: Int
            switch operation {
            case .addition: rightVal = safeROp1 + rOp2
            case .subtraction: rightVal = safeROp1 - rOp2
            case .multiplication: rightVal = safeROp1 * rOp2
            case .division: rightVal = rOp2 > 0 ? safeROp1 / rOp2 : 0
            }

            if leftVal >= rightVal {
                self.options = [0, 1]
            } else {
                self.options = [1, 0]
            }

        case .countingObjects, .visualAddition, .compareGroups, .tenFrame,
             .matchConnect, .numberBonds, .diceAddition, .evenOddSort, .visualSubtraction,
             .multiStep, .numberSequence, .areaPerimeter, .fractionPick, .longDivision:
            fatalError("Use the appropriate init for visual exercise types")
        }
    }

    init(emojiFormat: ExerciseFormat, emojiSymbol: String, count: Int, count2: Int = 0, emojiRight: String? = nil, difficulty: ExerciseDifficulty) {
        self.id = UUID().uuidString
        self.format = emojiFormat
        self.difficulty = difficulty
        self.operation = .addition
        self.operand1 = count
        self.operand2 = count2
        self.emojiSymbol = emojiSymbol
        self.emojiSymbolRight = emojiRight
        self.missingOperandIndex = nil
        self.proposedAnswer = nil
        self.comparisonLeft = nil
        self.comparisonRight = nil
        self.matchLeftLabels = nil
        self.matchRightLabels = nil
        self.correctMatchIndices = nil
        self.numberBondMissingWhole = nil
        self.sequenceNumbers = nil
        self.multiStepExpression = nil
        self.gridWidth = nil
        self.gridHeight = nil
        self.fractionNumerator = nil
        self.fractionDenominator = nil
        self.divisionRemainder = nil

        switch emojiFormat {
        case .countingObjects, .tenFrame:
            self.correctAnswer = count
            var opts = Set<Int>()
            opts.insert(count)
            var attempts = 0
            while opts.count < 4 && attempts < 50 {
                attempts += 1
                let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
                let wrong = count + offset
                if wrong >= 1 && wrong != count {
                    opts.insert(wrong)
                }
            }
            var fallback = count + 3
            while opts.count < 4 { opts.insert(fallback); fallback += 1 }
            self.options = Array(opts).shuffled()

        case .visualAddition:
            let total = count + count2
            self.correctAnswer = total
            var opts = Set<Int>()
            opts.insert(total)
            var attempts = 0
            while opts.count < 4 && attempts < 50 {
                attempts += 1
                let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
                let wrong = total + offset
                if wrong >= 1 && wrong != total {
                    opts.insert(wrong)
                }
            }
            var fallback = total + 3
            while opts.count < 4 { opts.insert(fallback); fallback += 1 }
            self.options = Array(opts).shuffled()

        case .compareGroups:
            self.correctAnswer = count > count2 ? 0 : 1
            self.options = count > count2 ? [0, 1] : [1, 0]

        default:
            fatalError("Use init(operand1:) for non-emoji exercise types")
        }
    }

    // MARK: - Match Connect init

    init(matchLeft: [String], matchRight: [String], correctIndices: [Int], difficulty: ExerciseDifficulty) {
        self.id = UUID().uuidString
        self.format = .matchConnect
        self.difficulty = difficulty
        self.operation = .addition
        self.operand1 = matchLeft.count
        self.operand2 = 0
        self.correctAnswer = matchLeft.count
        self.options = []
        self.emojiSymbol = nil
        self.emojiSymbolRight = nil
        self.missingOperandIndex = nil
        self.proposedAnswer = nil
        self.comparisonLeft = nil
        self.comparisonRight = nil
        self.matchLeftLabels = matchLeft
        self.matchRightLabels = matchRight
        self.correctMatchIndices = correctIndices
        self.numberBondMissingWhole = nil
        self.sequenceNumbers = nil
        self.multiStepExpression = nil
        self.gridWidth = nil
        self.gridHeight = nil
        self.fractionNumerator = nil
        self.fractionDenominator = nil
        self.divisionRemainder = nil
    }

    // MARK: - Number Bonds init

    init(numberBondWhole: Int, givenPart: Int, missingWhole: Bool, difficulty: ExerciseDifficulty) {
        self.id = UUID().uuidString
        self.format = .numberBonds
        self.difficulty = difficulty
        self.operation = .addition
        self.numberBondMissingWhole = missingWhole
        self.emojiSymbol = nil
        self.emojiSymbolRight = nil
        self.missingOperandIndex = nil
        self.proposedAnswer = nil
        self.comparisonLeft = nil
        self.comparisonRight = nil
        self.matchLeftLabels = nil
        self.matchRightLabels = nil
        self.correctMatchIndices = nil
        self.sequenceNumbers = nil
        self.multiStepExpression = nil
        self.gridWidth = nil
        self.gridHeight = nil
        self.fractionNumerator = nil
        self.fractionDenominator = nil
        self.divisionRemainder = nil

        if missingWhole {
            self.operand1 = givenPart
            self.operand2 = numberBondWhole - givenPart
            self.correctAnswer = numberBondWhole
        } else {
            self.operand1 = numberBondWhole
            self.operand2 = givenPart
            self.correctAnswer = numberBondWhole - givenPart
        }

        var opts = Set<Int>()
        opts.insert(correctAnswer)
        var attempts = 0
        while opts.count < 4 && attempts < 50 {
            attempts += 1
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let wrong = correctAnswer + offset
            if wrong >= 1 && wrong != correctAnswer {
                opts.insert(wrong)
            }
        }
        var fallback = correctAnswer + 4
        while opts.count < 4 { opts.insert(fallback); fallback += 1 }
        self.options = Array(opts).shuffled()
    }

    // MARK: - Dice / EvenOdd / Visual Subtraction init

    init(middleFormat: ExerciseFormat, op1: Int, op2: Int, operation: MathOperation, difficulty: ExerciseDifficulty, emoji: String? = nil) {
        self.id = UUID().uuidString
        self.format = middleFormat
        self.difficulty = difficulty
        self.operation = operation
        self.operand1 = op1
        self.operand2 = op2
        self.emojiSymbol = emoji
        self.emojiSymbolRight = nil
        self.missingOperandIndex = nil
        self.proposedAnswer = nil
        self.comparisonLeft = nil
        self.comparisonRight = nil
        self.matchLeftLabels = nil
        self.matchRightLabels = nil
        self.correctMatchIndices = nil
        self.numberBondMissingWhole = nil
        self.sequenceNumbers = nil
        self.multiStepExpression = nil
        self.gridWidth = nil
        self.gridHeight = nil
        self.fractionNumerator = nil
        self.fractionDenominator = nil
        self.divisionRemainder = nil

        let answer: Int
        switch operation {
        case .addition: answer = op1 + op2
        case .subtraction: answer = op1 - op2
        case .multiplication: answer = op1 * op2
        case .division: answer = op1 / op2
        }
        self.correctAnswer = answer

        var opts = Set<Int>()
        opts.insert(answer)
        var attempts = 0
        while opts.count < 4 && attempts < 50 {
            attempts += 1
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let wrong = answer + offset
            if wrong >= 0 && wrong != answer {
                opts.insert(wrong)
            }
        }
        var fallback = answer + 4
        while opts.count < 4 { opts.insert(fallback); fallback += 1 }
        self.options = Array(opts).shuffled()
    }

    // MARK: - Older Age Exercises init

    init(olderFormat: ExerciseFormat, answer: Int, options: [Int], difficulty: ExerciseDifficulty,
         expression: String? = nil, sequence: [Int]? = nil, width: Int? = nil, height: Int? = nil,
         fracNum: Int? = nil, fracDen: Int? = nil, remainder: Int? = nil,
         op1: Int = 0, op2: Int = 0, operation: MathOperation = .addition) {
        self.id = UUID().uuidString
        self.format = olderFormat
        self.difficulty = difficulty
        self.operation = operation
        self.operand1 = op1
        self.operand2 = op2
        self.correctAnswer = answer
        self.options = options
        self.emojiSymbol = nil
        self.emojiSymbolRight = nil
        self.missingOperandIndex = nil
        self.proposedAnswer = nil
        self.comparisonLeft = nil
        self.comparisonRight = nil
        self.matchLeftLabels = nil
        self.matchRightLabels = nil
        self.correctMatchIndices = nil
        self.numberBondMissingWhole = nil
        self.multiStepExpression = expression
        self.sequenceNumbers = sequence
        self.gridWidth = width
        self.gridHeight = height
        self.fractionNumerator = fracNum
        self.fractionDenominator = fracDen
        self.divisionRemainder = remainder
    }

    var prompt: String {
        switch format {
        case .countingObjects:
            return "\(emojiSymbol ?? "?") x\(operand1)"
        case .visualAddition:
            return "\(emojiSymbol ?? "?")x\(operand1) + \(emojiSymbol ?? "?")x\(operand2)"
        case .compareGroups:
            return "\(emojiSymbol ?? "?")x\(operand1) vs \(emojiSymbolRight ?? "?")x\(operand2)"
        case .tenFrame:
            return "[\(emojiSymbol ?? "?")x\(operand1)/10]"
        case .matchConnect:
            return "Match \(operand1) pairs"
        case .numberBonds:
            if numberBondMissingWhole == true {
                return "\(operand1) + \(operand2) = ?"
            }
            return "\(operand1) = \(operand2) + ?"
        case .diceAddition:
            return "🎲\(operand1) + 🎲\(operand2)"
        case .evenOddSort:
            return "\(operand1) \(operation.symbol) \(operand2)"
        case .visualSubtraction:
            return "\(emojiSymbol ?? "?")x\(operand1) - \(operand2)"
        case .multiStep:
            return multiStepExpression ?? "\(operand1) \(operation.symbol) \(operand2)"
        case .numberSequence:
            return (sequenceNumbers ?? []).map { "\($0)" }.joined(separator: ", ") + ", ?"
        case .areaPerimeter:
            return "\(gridWidth ?? 0)x\(gridHeight ?? 0)"
        case .fractionPick:
            return "\(fractionNumerator ?? 0)/\(fractionDenominator ?? 1)"
        case .longDivision:
            return "\(operand1) \u{00F7} \(operand2)"
        default:
            return "\(operand1) \(operation.symbol) \(operand2)"
        }
    }

    var missingNumberPrompt: String {
        guard let idx = missingOperandIndex else { return prompt }
        if idx == 0 {
            return "? \(operation.symbol) \(operand2) = \(correctAnswer)"
        } else {
            return "\(operand1) \(operation.symbol) ? = \(correctAnswer)"
        }
    }

    var missingNumberCorrectAnswer: Int {
        guard let idx = missingOperandIndex else { return correctAnswer }
        return idx == 0 ? operand1 : operand2
    }

    var trueFalsePrompt: String {
        guard let proposed = proposedAnswer else { return prompt }
        return "\(operand1) \(operation.symbol) \(operand2) = \(proposed)"
    }

    var trueFalseIsCorrect: Bool {
        proposedAnswer == correctAnswer
    }
}

nonisolated enum ExerciseDifficulty: Int, Codable, Sendable {
    case warmup = 0
    case normal = 1
    case harder = 2
    case challenge = 3

    static func forIndex(_ index: Int) -> ExerciseDifficulty {
        switch index {
        case 0..<5: return .warmup
        case 5..<10: return .normal
        case 10..<15: return .harder
        default: return .challenge
        }
    }
}

nonisolated struct ExerciseResult: Codable, Identifiable, Sendable {
    let id: String
    let chapterId: String
    let prompt: String
    let operationType: MathOperation
    let difficulty: ExerciseDifficulty
    var firstAttemptCorrect: Bool
    var secondAttemptCorrect: Bool?
    var attemptsUsed: Int
    let answeredAt: Date

    init(chapterId: String, exercise: Exercise, firstCorrect: Bool, secondCorrect: Bool?, attempts: Int) {
        self.id = UUID().uuidString
        self.chapterId = chapterId
        self.prompt = exercise.prompt
        self.operationType = exercise.operation
        self.difficulty = exercise.difficulty
        self.firstAttemptCorrect = firstCorrect
        self.secondAttemptCorrect = secondCorrect
        self.attemptsUsed = attempts
        self.answeredAt = Date()
    }

    var wasCorrect: Bool {
        firstAttemptCorrect || (secondAttemptCorrect ?? false)
    }
}
