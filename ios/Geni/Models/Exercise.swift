import Foundation

nonisolated enum ExerciseFormat: String, Codable, Sendable {
    case solveResult
    case missingNumber
    case trueFalse
    case comparison
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

        switch format {
        case .solveResult:
            self.missingOperandIndex = nil
            self.proposedAnswer = nil
            self.comparisonLeft = nil
            self.comparisonRight = nil

            var opts = Set<Int>()
            opts.insert(answer)
            while opts.count < 4 {
                let offset = Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
                let wrong = answer + offset
                if wrong >= 0 && wrong != answer {
                    opts.insert(wrong)
                }
            }
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
            while opts.count < 4 {
                let offset = Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
                let wrong = missingValue + offset
                if wrong >= 0 && wrong != missingValue {
                    opts.insert(wrong)
                }
            }
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
        }
    }

    var prompt: String {
        "\(operand1) \(operation.symbol) \(operand2)"
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
    let correctAnswer: Int
    let userAnswer: Int?
    let format: ExerciseFormat

    init(chapterId: String, exercise: Exercise, firstCorrect: Bool, secondCorrect: Bool?, attempts: Int, userAnswer: Int?, correctAnswer: Int) {
        self.id = UUID().uuidString
        self.chapterId = chapterId
        self.prompt = exercise.prompt
        self.operationType = exercise.operation
        self.difficulty = exercise.difficulty
        self.firstAttemptCorrect = firstCorrect
        self.secondAttemptCorrect = secondCorrect
        self.attemptsUsed = attempts
        self.answeredAt = Date()
        self.correctAnswer = correctAnswer
        self.userAnswer = userAnswer
        self.format = exercise.format
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chapterId = try container.decode(String.self, forKey: .chapterId)
        prompt = try container.decode(String.self, forKey: .prompt)
        operationType = try container.decode(MathOperation.self, forKey: .operationType)
        difficulty = try container.decode(ExerciseDifficulty.self, forKey: .difficulty)
        firstAttemptCorrect = try container.decode(Bool.self, forKey: .firstAttemptCorrect)
        secondAttemptCorrect = try container.decodeIfPresent(Bool.self, forKey: .secondAttemptCorrect)
        attemptsUsed = try container.decode(Int.self, forKey: .attemptsUsed)
        answeredAt = try container.decode(Date.self, forKey: .answeredAt)
        correctAnswer = (try? container.decode(Int.self, forKey: .correctAnswer)) ?? 0
        userAnswer = try? container.decode(Int.self, forKey: .userAnswer)
        format = (try? container.decode(ExerciseFormat.self, forKey: .format)) ?? .solveResult
    }

    var wasCorrect: Bool {
        firstAttemptCorrect || (secondAttemptCorrect ?? false)
    }
}
