import Foundation

nonisolated struct ReadingSession: Codable, Identifiable, Sendable {
    let id: String
    let childId: String
    let date: String
    let readingTextId: String
    var mode: ReadingMode
    var readingTimeSeconds: Int
    var targetTimeSeconds: Int
    var isCompleted: Bool
    var coinsEarned: Int
    var completedAt: Date?

    init(childId: String, date: String, readingTextId: String, mode: ReadingMode, targetTimeSeconds: Int) {
        self.id = UUID().uuidString
        self.childId = childId
        self.date = date
        self.readingTextId = readingTextId
        self.mode = mode
        self.readingTimeSeconds = 0
        self.targetTimeSeconds = targetTimeSeconds
        self.isCompleted = false
        self.coinsEarned = 0
    }

    mutating func complete() {
        isCompleted = true
        completedAt = Date()
        coinsEarned = 15
    }
}
