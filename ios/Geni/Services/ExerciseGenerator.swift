import Foundation

private enum EmojiPool {
    static let fruits = ["🍎", "🍊", "🍋", "🍇", "🍓", "🍌", "🍒"]
    static let animals = ["🐱", "🐶", "🐰", "🐻", "🐸", "🦊", "🐧"]
    static let nature = ["🌸", "⭐", "🌈", "☀️", "🌺", "🍀"]
    static let food = ["🧁", "🍪", "🍩", "🎂", "🍕"]

    static let allCategories = [fruits, animals, nature, food]

    static func randomEmoji() -> String {
        allCategories.randomElement()!.randomElement()!
    }

    static func twoDifferentEmojis() -> (String, String) {
        let cats = allCategories.shuffled()
        return (cats[0].randomElement()!, cats[1].randomElement()!)
    }
}

enum ExerciseGenerator {
    static func generateChapter(profile: ChildProfile, chapterType: ChapterType = .daily) -> [Exercise] {
        var exercises: [Exercise] = []
        let ops = profile.operationsEnabled

        let emojiFormats: Set<ExerciseFormat> = [.countingObjects, .visualAddition, .compareGroups, .tenFrame]
        let middleFormats: Set<ExerciseFormat> = [.numberBonds, .diceAddition, .evenOddSort, .visualSubtraction]

        var i = 0
        while i < 20 {
            let difficulty = ExerciseDifficulty.forIndex(i)
            let format = pickFormat(index: i, ageGroup: profile.ageGroup, chapterType: chapterType)
            if format == .matchConnect {
                let exercise = generateMatchConnectExercise(difficulty: difficulty, ageGroup: profile.ageGroup, ops: ops)
                exercises.append(exercise)
                // matchConnect counts as 3 exercises worth
                i += 3
            } else if emojiFormats.contains(format) {
                exercises.append(generateEmojiExercise(format: format, difficulty: difficulty))
                i += 1
            } else if middleFormats.contains(format) {
                exercises.append(generateMiddleExercise(format: format, difficulty: difficulty, ageGroup: profile.ageGroup, ops: ops))
                i += 1
            } else {
                let operation = ops[Int.random(in: 0..<ops.count)]
                exercises.append(generateExercise(operation: operation, difficulty: difficulty, ageGroup: profile.ageGroup, format: format))
                i += 1
            }
        }

        return exercises
    }

    static func generateTopicChapter(profile: ChildProfile, topic: MathTopic) -> [Exercise] {
        var exercises: [Exercise] = []
        let ops = profile.operationsEnabled
        let emojiFormats: Set<ExerciseFormat> = [.countingObjects, .visualAddition, .compareGroups, .tenFrame]
        let middleFormats: Set<ExerciseFormat> = [.numberBonds, .diceAddition, .evenOddSort, .visualSubtraction]
        let topicFormats = topic.formats

        var i = 0
        while i < 20 {
            let difficulty = ExerciseDifficulty.forIndex(i)
            let format = topicFormats[Int.random(in: 0..<topicFormats.count)]

            if format == .matchConnect {
                exercises.append(generateMatchConnectExercise(difficulty: difficulty, ageGroup: profile.ageGroup, ops: ops))
                i += 3
            } else if emojiFormats.contains(format) {
                exercises.append(generateEmojiExercise(format: format, difficulty: difficulty))
                i += 1
            } else if middleFormats.contains(format) {
                exercises.append(generateMiddleExercise(format: format, difficulty: difficulty, ageGroup: profile.ageGroup, ops: ops))
                i += 1
            } else {
                let operation = ops[Int.random(in: 0..<ops.count)]
                exercises.append(generateExercise(operation: operation, difficulty: difficulty, ageGroup: profile.ageGroup, format: format))
                i += 1
            }
        }
        return exercises
    }

    static func generateSpotlightChapter(profile: ChildProfile, operation: MathOperation) -> [Exercise] {
        var exercises: [Exercise] = []
        for i in 0..<20 {
            let difficulty = ExerciseDifficulty.forIndex(i)
            let format = pickFormat(index: i, ageGroup: profile.ageGroup, chapterType: .operationSpotlight)
            let exercise = generateExercise(operation: operation, difficulty: difficulty, ageGroup: profile.ageGroup, format: format)
            exercises.append(exercise)
        }
        return exercises
    }

    private static func pickFormat(index: Int, ageGroup: AgeGroup, chapterType: ChapterType) -> ExerciseFormat {
        if chapterType == .timeAttack || chapterType == .perfectRun {
            return .solveResult
        }

        let roll = Int.random(in: 0..<10)
        switch ageGroup {
        case .young:
            if index < 5 {
                return [.countingObjects, .countingObjects, .countingObjects, .tenFrame, .countingObjects][index]
            }
            if roll < 2 { return .countingObjects }
            if roll < 4 { return .visualAddition }
            if roll < 5 { return .compareGroups }
            if roll < 6 { return .tenFrame }
            if roll < 8 { return .solveResult }
            if roll < 9 { return .trueFalse }
            return .missingNumber
        case .middle:
            if index < 3 { return .solveResult }
            if roll < 2 { return .solveResult }
            if roll < 3 { return .missingNumber }
            if roll < 4 { return .trueFalse }
            if roll < 5 { return .numberBonds }
            if roll < 6 { return .diceAddition }
            if roll < 7 { return .evenOddSort }
            if roll < 8 { return .matchConnect }
            if roll < 9 { return .visualSubtraction }
            return .comparison
        case .older:
            if roll < 3 { return .solveResult }
            if roll < 5 { return .missingNumber }
            if roll < 7 { return .trueFalse }
            return .comparison
        }
    }

    static func generateExercise(operation: MathOperation, difficulty: ExerciseDifficulty, ageGroup: AgeGroup, format: ExerciseFormat = .solveResult) -> Exercise {
        let (op1, op2) = generateOperands(operation: operation, difficulty: difficulty, ageGroup: ageGroup)
        return Exercise(operand1: op1, operand2: op2, operation: operation, difficulty: difficulty, format: format)
    }

    static func generateEmojiExercise(format: ExerciseFormat, difficulty: ExerciseDifficulty) -> Exercise {
        switch format {
        case .countingObjects:
            let count: Int
            switch difficulty {
            case .warmup: count = Int.random(in: 1...5)
            case .normal: count = Int.random(in: 3...7)
            case .harder: count = Int.random(in: 5...8)
            case .challenge: count = Int.random(in: 6...10)
            }
            return Exercise(emojiFormat: .countingObjects, emojiSymbol: EmojiPool.randomEmoji(), count: count, difficulty: difficulty)

        case .visualAddition:
            let (left, right): (Int, Int)
            switch difficulty {
            case .warmup: left = Int.random(in: 1...3); right = Int.random(in: 1...2)
            case .normal: left = Int.random(in: 2...4); right = Int.random(in: 1...3)
            case .harder: left = Int.random(in: 3...5); right = Int.random(in: 2...4)
            case .challenge: left = Int.random(in: 3...5); right = Int.random(in: 2...5)
            }
            return Exercise(emojiFormat: .visualAddition, emojiSymbol: EmojiPool.randomEmoji(), count: left, count2: right, difficulty: difficulty)

        case .compareGroups:
            let (left, right): (Int, Int)
            switch difficulty {
            case .warmup:
                left = Int.random(in: 1...4)
                right = left + Int.random(in: 3...4) * (Bool.random() ? 1 : -1)
            case .normal:
                left = Int.random(in: 2...6)
                right = left + Int.random(in: 2...3) * (Bool.random() ? 1 : -1)
            case .harder:
                left = Int.random(in: 3...7)
                right = left + Int.random(in: 1...2) * (Bool.random() ? 1 : -1)
            case .challenge:
                left = Int.random(in: 4...9)
                right = left + (Bool.random() ? 1 : -1)
            }
            let safeLeft = max(left, 1)
            let safeRight = max(right, 1)
            let finalLeft = safeLeft == safeRight ? safeLeft + 1 : safeLeft
            let (e1, e2) = EmojiPool.twoDifferentEmojis()
            return Exercise(emojiFormat: .compareGroups, emojiSymbol: e1, count: finalLeft, count2: safeRight, emojiRight: e2, difficulty: difficulty)

        case .tenFrame:
            let count: Int
            switch difficulty {
            case .warmup: count = Int.random(in: 1...5)
            case .normal: count = Int.random(in: 3...7)
            case .harder: count = Int.random(in: 5...8)
            case .challenge: count = Int.random(in: 6...10)
            }
            return Exercise(emojiFormat: .tenFrame, emojiSymbol: EmojiPool.randomEmoji(), count: count, difficulty: difficulty)

        default:
            fatalError("Not an emoji format")
        }
    }

    // MARK: - Middle Age Format Generators

    static func generateMiddleExercise(format: ExerciseFormat, difficulty: ExerciseDifficulty, ageGroup: AgeGroup, ops: [MathOperation]) -> Exercise {
        switch format {
        case .numberBonds:
            return generateNumberBondExercise(difficulty: difficulty)
        case .diceAddition:
            return generateDiceExercise(difficulty: difficulty)
        case .evenOddSort:
            let op = ops[Int.random(in: 0..<ops.count)]
            return generateEvenOddExercise(difficulty: difficulty, ageGroup: ageGroup, operation: op)
        case .visualSubtraction:
            return generateVisualSubtractionExercise(difficulty: difficulty, ageGroup: ageGroup)
        default:
            fatalError("Not a middle format: \(format)")
        }
    }

    static func generateMatchConnectExercise(difficulty: ExerciseDifficulty, ageGroup: AgeGroup, ops: [MathOperation]) -> Exercise {
        let pairCount = difficulty == .warmup ? 3 : 4
        var leftLabels: [String] = []
        var rightLabels: [String] = []
        var answers: [Int] = []

        for _ in 0..<pairCount {
            let op = ops[Int.random(in: 0..<ops.count)]
            let (a, b) = generateOperands(operation: op, difficulty: difficulty, ageGroup: ageGroup)
            let result: Int
            switch op {
            case .addition: result = a + b
            case .subtraction: result = a - b
            case .multiplication: result = a * b
            case .division: result = a / b
            }
            leftLabels.append("\(a) \(op.symbol) \(b)")
            answers.append(result)
        }

        // Ensure unique answers - regenerate if duplicates
        var seen = Set<Int>()
        for i in 0..<answers.count {
            while seen.contains(answers[i]) {
                answers[i] += 1
                let op = ops[Int.random(in: 0..<ops.count)]
                let newA = answers[i]
                let newB = Int.random(in: 1...3)
                leftLabels[i] = "\(newA - newB) \(op.symbol) \(newB)"
                answers[i] = newA
            }
            seen.insert(answers[i])
        }

        rightLabels = answers.map { "\($0)" }

        // Shuffle right side and build index mapping
        var shuffledIndices = Array(0..<pairCount)
        shuffledIndices.shuffle()
        let shuffledRight = shuffledIndices.map { rightLabels[$0] }
        var correctIndices: [Int] = Array(repeating: 0, count: pairCount)
        for i in 0..<pairCount {
            correctIndices[i] = shuffledIndices.firstIndex(of: i)!
        }

        return Exercise(matchLeft: leftLabels, matchRight: shuffledRight, correctIndices: correctIndices, difficulty: difficulty)
    }

    static func generateNumberBondExercise(difficulty: ExerciseDifficulty) -> Exercise {
        let whole: Int
        switch difficulty {
        case .warmup: whole = Int.random(in: 5...10)
        case .normal: whole = Int.random(in: 8...15)
        case .harder: whole = Int.random(in: 10...18)
        case .challenge: whole = Int.random(in: 12...20)
        }
        let part = Int.random(in: 1...(whole - 1))
        let missingWhole = Bool.random() && difficulty.rawValue >= 2
        return Exercise(numberBondWhole: whole, givenPart: part, missingWhole: missingWhole, difficulty: difficulty)
    }

    static func generateDiceExercise(difficulty: ExerciseDifficulty) -> Exercise {
        let (d1, d2): (Int, Int)
        switch difficulty {
        case .warmup: d1 = Int.random(in: 1...3); d2 = Int.random(in: 1...3)
        case .normal: d1 = Int.random(in: 1...4); d2 = Int.random(in: 1...4)
        case .harder: d1 = Int.random(in: 2...6); d2 = Int.random(in: 1...5)
        case .challenge: d1 = Int.random(in: 1...6); d2 = Int.random(in: 1...6)
        }
        return Exercise(middleFormat: .diceAddition, op1: d1, op2: d2, operation: .addition, difficulty: difficulty)
    }

    static func generateEvenOddExercise(difficulty: ExerciseDifficulty, ageGroup: AgeGroup, operation: MathOperation) -> Exercise {
        let (a, b) = generateOperands(operation: operation, difficulty: difficulty, ageGroup: ageGroup)
        return Exercise(middleFormat: .evenOddSort, op1: a, op2: b, operation: operation, difficulty: difficulty)
    }

    static func generateVisualSubtractionExercise(difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> Exercise {
        let (a, b) = subtractionOperands(difficulty: difficulty, ageGroup: ageGroup)
        return Exercise(middleFormat: .visualSubtraction, op1: a, op2: b, operation: .subtraction, difficulty: difficulty, emoji: EmojiPool.randomEmoji())
    }

    private static func generateOperands(operation: MathOperation, difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> (Int, Int) {
        switch operation {
        case .addition:
            return additionOperands(difficulty: difficulty, ageGroup: ageGroup)
        case .subtraction:
            return subtractionOperands(difficulty: difficulty, ageGroup: ageGroup)
        case .multiplication:
            return multiplicationOperands(difficulty: difficulty, ageGroup: ageGroup)
        case .division:
            return divisionOperands(difficulty: difficulty, ageGroup: ageGroup)
        }
    }

    private static func additionOperands(difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> (Int, Int) {
        switch (ageGroup, difficulty) {
        case (.young, .warmup):
            return (Int.random(in: 1...5), Int.random(in: 1...3))
        case (.young, .normal):
            return (Int.random(in: 2...8), Int.random(in: 1...5))
        case (.young, .harder):
            return (Int.random(in: 3...10), Int.random(in: 2...7))
        case (.young, .challenge):
            return (Int.random(in: 5...10), Int.random(in: 3...10))
        case (.middle, .warmup):
            return (Int.random(in: 5...15), Int.random(in: 1...10))
        case (.middle, .normal):
            return (Int.random(in: 10...30), Int.random(in: 5...20))
        case (.middle, .harder):
            return (Int.random(in: 15...50), Int.random(in: 10...30))
        case (.middle, .challenge):
            return (Int.random(in: 20...70), Int.random(in: 15...50))
        case (.older, .warmup):
            return (Int.random(in: 10...50), Int.random(in: 5...30))
        case (.older, .normal):
            return (Int.random(in: 25...75), Int.random(in: 15...50))
        case (.older, .harder):
            return (Int.random(in: 50...100), Int.random(in: 25...75))
        case (.older, .challenge):
            return (Int.random(in: 50...150), Int.random(in: 50...100))
        }
    }

    private static func subtractionOperands(difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> (Int, Int) {
        let (a, b) = additionOperands(difficulty: difficulty, ageGroup: ageGroup)
        let larger = max(a, b) + abs(a - b)
        let smaller = min(a, b)
        return (larger, smaller)
    }

    private static func multiplicationOperands(difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> (Int, Int) {
        switch (ageGroup, difficulty) {
        case (_, .warmup):
            return (Int.random(in: 1...3), Int.random(in: 1...5))
        case (_, .normal):
            return (Int.random(in: 2...5), Int.random(in: 2...6))
        case (.older, .harder):
            return (Int.random(in: 3...9), Int.random(in: 3...8))
        case (.older, .challenge):
            return (Int.random(in: 4...12), Int.random(in: 4...10))
        default:
            return (Int.random(in: 2...7), Int.random(in: 2...7))
        }
    }

    private static func divisionOperands(difficulty: ExerciseDifficulty, ageGroup: AgeGroup) -> (Int, Int) {
        let divisor: Int
        let quotient: Int

        switch difficulty {
        case .warmup:
            divisor = Int.random(in: 1...3)
            quotient = Int.random(in: 1...5)
        case .normal:
            divisor = Int.random(in: 2...5)
            quotient = Int.random(in: 2...6)
        case .harder:
            divisor = Int.random(in: 2...8)
            quotient = Int.random(in: 2...8)
        case .challenge:
            divisor = Int.random(in: 3...10)
            quotient = Int.random(in: 3...10)
        }

        return (divisor * quotient, divisor)
    }
}
