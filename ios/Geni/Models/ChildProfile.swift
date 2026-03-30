import Foundation

nonisolated enum MathTopic: String, Codable, CaseIterable, Sendable {
    case numbers
    case addSubBasic
    case strategies
    case tensCrossing
    case timeAndCalendar
    case largerNumbers
    case addSubAdvanced
    case problemSolving
    case measurement
    case logicPatterns

    var order: Int { Self.allCases.firstIndex(of: self)! }

    var starsToUnlock: Int { order * 10 }

    var emoji: String {
        switch self {
        case .numbers: return "🔢"
        case .addSubBasic: return "➕"
        case .strategies: return "🎲"
        case .tensCrossing: return "🔟"
        case .timeAndCalendar: return "🕐"
        case .largerNumbers: return "💯"
        case .addSubAdvanced: return "🧮"
        case .problemSolving: return "🧩"
        case .measurement: return "📏"
        case .logicPatterns: return "🧠"
        }
    }

    var displayName: String {
        switch self {
        case .numbers: return L.s(.topicNumbers)
        case .addSubBasic: return L.s(.topicAddSubBasic)
        case .strategies: return L.s(.topicStrategies)
        case .tensCrossing: return L.s(.topicTensCrossing)
        case .timeAndCalendar: return L.s(.topicTimeAndCalendar)
        case .largerNumbers: return L.s(.topicLargerNumbers)
        case .addSubAdvanced: return L.s(.topicAddSubAdvanced)
        case .problemSolving: return L.s(.topicProblemSolving)
        case .measurement: return L.s(.topicMeasurement)
        case .logicPatterns: return L.s(.topicLogicPatterns)
        }
    }

    var next: MathTopic? {
        let all = Self.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[all.index(after: idx)]
    }

    var formats: [ExerciseFormat] {
        switch self {
        case .numbers: return [.countingObjects, .evenOddSort, .numberBonds, .solveResult]
        case .addSubBasic: return [.solveResult, .visualSubtraction, .visualAddition, .trueFalse]
        case .strategies: return [.diceAddition, .numberBonds, .matchConnect, .missingNumber]
        case .tensCrossing: return [.tenFrame, .solveResult, .numberBonds, .missingNumber]
        case .timeAndCalendar: return [.matchConnect, .solveResult, .trueFalse]
        case .largerNumbers: return [.solveResult, .comparison, .matchConnect, .missingNumber]
        case .addSubAdvanced: return [.solveResult, .missingNumber, .matchConnect, .trueFalse]
        case .problemSolving: return [.matchConnect, .solveResult, .missingNumber]
        case .measurement: return [.comparison, .matchConnect, .solveResult]
        case .logicPatterns: return [.matchConnect, .missingNumber, .solveResult]
        }
    }
}

nonisolated struct TopicProgress: Codable, Sendable {
    var topicStars: [String: Int] = [:]

    func stars(for topic: MathTopic) -> Int {
        topicStars[topic.rawValue] ?? 0
    }

    mutating func addStars(_ count: Int, for topic: MathTopic) {
        topicStars[topic.rawValue, default: 0] += count
    }

    func isUnlocked(_ topic: MathTopic) -> Bool {
        if topic.order == 0 { return true }
        guard let prev = MathTopic.allCases.first(where: { $0.order == topic.order - 1 }) else { return true }
        return stars(for: prev) >= topic.starsToUnlock
    }

    func currentTopic() -> MathTopic {
        for topic in MathTopic.allCases.reversed() {
            if isUnlocked(topic) { return topic }
        }
        return .numbers
    }
}

nonisolated struct ChildProfile: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var nickname: String
    var age: Int
    var avatarId: String
    var operationsEnabled: [MathOperation]
    var remindersEnabled: Bool
    var adaptiveDifficultyEnabled: Bool
    let createdAt: Date

    init(nickname: String, age: Int, avatarId: String) {
        self.id = UUID().uuidString
        self.nickname = nickname
        self.age = age
        self.avatarId = avatarId
        self.operationsEnabled = MathOperation.recommended(for: age)
        self.remindersEnabled = false
        self.adaptiveDifficultyEnabled = false
        self.createdAt = Date()
    }

    var ageGroup: AgeGroup {
        AgeGroup.from(age: age)
    }
}

nonisolated enum AgeGroup: String, Codable, Sendable {
    case young
    case middle
    case older

    static func from(age: Int) -> AgeGroup {
        switch age {
        case ...6: return .young
        case 7...8: return .middle
        default: return .older
        }
    }

    var useDragAndDrop: Bool {
        self != .older
    }
}

nonisolated enum MathOperation: String, Codable, Sendable, CaseIterable, Hashable {
    case addition
    case subtraction
    case multiplication
    case division

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "\u{2212}"
        case .multiplication: return "\u{00D7}"
        case .division: return "\u{00F7}"
        }
    }

    var emoji: String {
        switch self {
        case .addition: return "➕"
        case .subtraction: return "➖"
        case .multiplication: return "✖️"
        case .division: return "➗"
        }
    }

    var example: String {
        switch self {
        case .addition: return "2 + 3"
        case .subtraction: return "5 \u{2212} 2"
        case .multiplication: return "3 \u{00D7} 4"
        case .division: return "8 \u{00F7} 2"
        }
    }

    var displayName: String {
        switch self {
        case .addition: return L.s(.addition)
        case .subtraction: return L.s(.subtraction)
        case .multiplication: return L.s(.multiplication)
        case .division: return L.s(.division)
        }
    }

    static func recommended(for age: Int) -> [MathOperation] {
        switch age {
        case ...6: return [.addition, .subtraction]
        case 7...8: return [.addition, .subtraction, .multiplication]
        default: return [.addition, .subtraction, .multiplication, .division]
        }
    }
}
