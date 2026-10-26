import SwiftUI

// Ages 4–5, what kindergartens (barnehage / EYFS) teach: first and last in a queue, on/under/next to,
// numbers shown on fingers, big and small. Pictures only; the question is read aloud.
// Scenes are separate from the answer tiles; big/small compares pictures inside the tiles.

enum EarlyYearsGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .ordinal: return ordinal(age: age, difficulty: difficulty)
        case .position: return position(age: age, difficulty: difficulty)
        case .fingerNumbers: return fingerNumbers(age: age, difficulty: difficulty)
        default: return bigSmall(age: age, difficulty: difficulty)
        }
    }
}

struct EarlyYearsGameView: View {
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        switch spec.payload {
        case let payload as OrdinalPayload:
            OrdinalGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        case let payload as PositionPayload:
            PositionGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        case let payload as FingerPayload:
            FingerGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        case let payload as BigSmallPayload:
            BigSmallGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        case let payload as ChoicePayload:
            ChoiceGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        default:
            EmptyView()
        }
    }
}

extension EarlyYearsGames {
    /// Distinct values near `answer` within `range`, the answer included, shuffled.
    static func nearby(_ answer: Int, count: Int, in range: ClosedRange<Int>) -> [Int] {
        let others = range.filter { $0 != answer }
            .shuffled()
            .sorted { abs($0 - answer) < abs($1 - answer) }
            .prefix(count - 1)
        return (Array(others) + [answer]).shuffled()
    }
}
