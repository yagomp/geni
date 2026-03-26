import Foundation

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
