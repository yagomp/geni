import Foundation

nonisolated enum ReadingMode: String, Codable, Sendable {
    case readByMyself
    case readToMe
    case listenToMeRead
}

nonisolated struct ReadingText: Codable, Identifiable, Sendable {
    let id: String
    let titleEN: String
    let titleNO: String
    let titleES: String
    let titlePT: String
    let contentEN: String
    let contentNO: String
    let contentES: String
    let contentPT: String
    let ageGroup: AgeGroup

    var title: String {
        switch L.selectedLanguage {
        case .english: return titleEN
        case .norwegian: return titleNO
        case .spanish: return titleES
        case .portuguese: return titlePT
        }
    }

    var content: String {
        switch L.selectedLanguage {
        case .english: return contentEN
        case .norwegian: return contentNO
        case .spanish: return contentES
        case .portuguese: return contentPT
        }
    }

    var words: [String] {
        content.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    static func targetReadingSeconds(for age: Int) -> Int {
        switch age {
        case ...6: return 180
        case 7...8: return 300
        default: return 420
        }
    }
}

nonisolated struct ReadingWord: Identifiable, Sendable {
    let id: Int
    let text: String
    let startIndex: Int
    let endIndex: Int

    var pauseDuration: Double {
        guard let last = text.last else { return 0 }
        switch last {
        case ".", "!", "?": return 0.6
        case ",": return 0.3
        case ":", ";": return 0.4
        default: return 0
        }
    }
}
