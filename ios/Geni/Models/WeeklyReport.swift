import Foundation

nonisolated struct WeeklyReport: Sendable {
    let childId: String
    let childName: String
    let weekStartDate: String
    let daysActive: Int
    let totalExercises: Int
    let correctCount: Int
    let accuracy: Int
    let streakStatus: Int
    let strongOperations: [MathOperation]
    let weakOperations: [MathOperation]
    let chaptersCompleted: Int
    let readingSessions: Int
}
