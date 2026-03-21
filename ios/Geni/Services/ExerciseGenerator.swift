import Foundation

enum ExerciseGenerator {
    static func generateChapter(profile: ChildProfile, chapterType: ChapterType = .daily) -> [Exercise] {
        var exercises: [Exercise] = []
        let ops = profile.operationsEnabled

        for i in 0..<20 {
            let difficulty = ExerciseDifficulty.forIndex(i)
            let operation = ops[Int.random(in: 0..<ops.count)]
            let format = pickFormat(index: i, ageGroup: profile.ageGroup, chapterType: chapterType)
            let exercise = generateExercise(operation: operation, difficulty: difficulty, ageGroup: profile.ageGroup, format: format)
            exercises.append(exercise)
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
            if index < 5 { return .solveResult }
            if roll < 6 { return .solveResult }
            if roll < 8 { return .trueFalse }
            return .missingNumber
        case .middle:
            if index < 3 { return .solveResult }
            if roll < 4 { return .solveResult }
            if roll < 6 { return .missingNumber }
            if roll < 8 { return .trueFalse }
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
