import Foundation

/// Step-by-step instructions in play (LK20): guide a robot to a star with arrows, then with loops;
/// and finish a mirror picture.
enum CodingGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .codingLoop: return robotGame(.codingLoop, age: age, difficulty: difficulty)
        case .symmetry: return symmetry(age: age, difficulty: difficulty)
        default: return robotGame(.codingPath, age: age, difficulty: difficulty)
        }
    }

    // MARK: - Robot grid

    /// Grid size for a robot game: 4×4 for the youngest, 5×5 once paths get long.
    static func gridSize(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Int {
        if kind == .codingLoop || age >= 9 { return 5 }
        return age == 8 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue ? 5 : 4
    }

    static func rockCount(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Int {
        switch difficulty {
        case .warmup: return 0
        case .normal: return age >= 8 || kind == .codingLoop ? 1 : 0
        case .harder: return 1
        case .challenge: return 2
        }
    }

    /// Arrow count of the right answer (codingPath): grows with age and difficulty.
    static func pathLength(age: Int, difficulty: ExerciseDifficulty) -> ClosedRange<Int> {
        let base = min(max(age, 7), 9) - 5 // 2, 3, 4
        switch difficulty {
        case .warmup: return base...base
        case .normal: return base...(base + 1)
        case .harder: return (base + 1)...(base + 2)
        case .challenge: return (base + 2)...(base + 3)
        }
    }

    private static func robotGame(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let size = gridSize(kind, age: age, difficulty: difficulty)
        let rocks = rockCount(kind, age: age, difficulty: difficulty)
        for _ in 0..<200 {
            let correct = kind == .codingLoop
                ? loopProgram(difficulty: difficulty, size: size)
                : pathProgram(length: Int.random(in: pathLength(age: age, difficulty: difficulty)), size: size,
                              turns: difficulty == .warmup ? .one : .any)
            if let exercise = robotExercise(kind, correct: correct, size: size, rocks: rocks, difficulty: difficulty) {
                return exercise
            }
        }
        return fallbackRobotExercise(kind, age: age, difficulty: difficulty)
    }

    /// Fully constructed, deterministic puzzle if random generation exhausts its attempts.
    static func fallbackRobotExercise(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let size = gridSize(kind, age: age, difficulty: difficulty)
        let correct: CodingProgram
        let wrong: [CodingProgram]
        if kind == .codingLoop {
            correct = [CodingStep([.right], times: 2), CodingStep(.down)]
            wrong = [[CodingStep([.left], times: 2), CodingStep(.down)],
                     [CodingStep([.right], times: 2), CodingStep(.up)]]
        } else {
            let length = pathLength(age: age, difficulty: difficulty).lowerBound
            let across = min(size - 1, length - 1)
            correct = Array(repeating: CodingStep(.right), count: across)
                + Array(repeating: CodingStep(.down), count: length - across)
            wrong = [[CodingStep(.left)] + correct.dropFirst(),
                     [CodingStep(.up)] + correct.dropFirst()]
        }
        let start = CodingCell(0, 0)
        var star = start
        var onPath: Set<CodingCell> = [start]
        for move in correct.flattened {
            star = star.moved(move)
            onPath.insert(star)
        }
        let free = (0..<size).flatMap { row in (0..<size).map { CodingCell($0, row) } }
            .filter { !onPath.contains($0) }
        let rocks = Set(free.prefix(rockCount(kind, age: age, difficulty: difficulty)))
        let board = CodingBoard(size: size, robot: start, star: star, rocks: rocks)
        let programs = [correct] + wrong
        let choices = programs.enumerated().map { GameChoice(label: label(for: $1), value: $0 + 1) }
        let payload = CodingGridPayload(board: board, programs: programs, choices: choices)
        return Exercise(game: GameSpec(kind: kind, prompt: robotPrompt(kind), answerText: label(for: correct), payload: payload),
                        correctAnswer: 1, options: choices.map(\.value), difficulty: difficulty)
    }

    private enum Turns { case one, any }

    /// A shortest route: `length` single arrows, some across and some up/down, never doubling back.
    private static func pathProgram(length: Int, size: Int, turns: Turns) -> CodingProgram {
        let length = min(length, 2 * (size - 1))
        let across = Int.random(in: max(1, length - (size - 1))...min(length - 1, size - 1))
        let h: CodingMove = Bool.random() ? .right : .left
        let v: CodingMove = Bool.random() ? .down : .up
        var moves = Array(repeating: h, count: across) + Array(repeating: v, count: length - across)
        switch turns {
        case .one: if Bool.random() { moves.reverse() }
        case .any: moves.shuffle()
        }
        return moves.map { CodingStep($0) }
    }

    /// A short program with loops; every route is a shortest one so the star is the obvious goal.
    private static func loopProgram(difficulty: ExerciseDifficulty, size: Int) -> CodingProgram {
        let h: CodingMove = Bool.random() ? .right : .left
        let v: CodingMove = Bool.random() ? .down : .up
        let (first, second) = Bool.random() ? (h, v) : (v, h)
        let most = size - 1
        switch difficulty {
        case .warmup:
            // ×3 → then ↓
            let program = [CodingStep([first], times: Int.random(in: 2...most)), CodingStep(second)]
            return Bool.random() ? program : Array(program.reversed())
        case .normal:
            // ×3 → then ×2 ↓
            return [CodingStep([first], times: Int.random(in: 2...most)), CodingStep([second], times: Int.random(in: 2...most))]
        case .harder:
            // ×3 (→ ↓): a staircase
            return [CodingStep([first, second], times: Int.random(in: 2...most))]
        case .challenge:
            // ×2 (→ ↓) then ×2 →, or the other way round
            let stairs = Int.random(in: 2...(most - 1))
            let run = Int.random(in: 1...(most - stairs))
            let program = [CodingStep([first, second], times: stairs),
                           run == 1 ? CodingStep(Bool.random() ? first : second)
                                    : CodingStep([Bool.random() ? first : second], times: run)]
            return Bool.random() ? program : Array(program.reversed())
        }
    }

    /// Places the program on the grid, adds rocks and two wrong programs. Nil when it doesn't work out.
    private static func robotExercise(_ kind: GameKind, correct: CodingProgram, size: Int, rocks rockCount: Int,
                                      difficulty: ExerciseDifficulty, start fixedStart: CodingCell? = nil) -> Exercise? {
        let moves = correct.flattened
        let starts = (0..<size).flatMap { r in (0..<size).map { CodingCell($0, r) } }.filter {
            route(moves, from: $0, size: size) != nil
        }
        guard let start = fixedStart ?? starts.randomElement(), let path = route(moves, from: start, size: size),
              let star = path.last, star != start else { return nil }
        let onPath = Set(path).union([start])

        var candidates = distractors(of: correct).shuffled()
        var rocks: [CodingCell] = []
        // First rock blocks a wrong route that would otherwise also reach the star.
        if rockCount > 0 {
            for candidate in candidates {
                guard let other = route(candidate.flattened, from: start, size: size), other.last == star else { continue }
                if let cell = other.filter({ !onPath.contains($0) }).randomElement() {
                    rocks.append(cell)
                    break
                }
            }
        }
        let free = (0..<size).flatMap { r in (0..<size).map { CodingCell($0, r) } }
            .filter { !onPath.contains($0) && !rocks.contains($0) }.shuffled()
        rocks += free.prefix(max(0, rockCount - rocks.count))

        let board = CodingBoard(size: size, robot: start, star: star, rocks: Set(rocks))
        guard board.run(correct) == .reachesStar else { return nil }

        // Wrong ones: must fail, look different, and not give the answer away by length.
        var seen: Set<[CodingMove]> = [moves]
        candidates = candidates.filter { board.run($0) != .reachesStar && seen.insert($0.flattened).inserted }
        // Bumping into the rock first, then falling off the grid.
        let crashing = candidates.filter { board.run($0) == .crashes }
            .sorted { (route($0.flattened, from: start, size: size) != nil ? 0 : 1) < (route($1.flattened, from: start, size: size) != nil ? 0 : 1) }
        let sameLength = candidates.filter { $0.flattened.count == moves.count && board.run($0) != .crashes }
        var wrong: [CodingProgram] = []
        for pick in [crashing.first, sameLength.first, sameLength.dropFirst().first] + candidates.map(Optional.some) {
            guard let pick, wrong.count < 2, !wrong.contains(pick) else { continue }
            wrong.append(pick)
        }
        guard wrong.count == 2 else { return nil }

        let programs = ([correct] + wrong).shuffled()
        let choices = programs.enumerated().map { GameChoice(label: label(for: $1), value: $0 + 1) }
        guard let answerIndex = programs.firstIndex(of: correct) else { return nil }
        let answer = choices[answerIndex]
        let payload = CodingGridPayload(board: board, programs: programs, choices: choices)
        return Exercise(game: GameSpec(kind: kind, prompt: robotPrompt(kind), answerText: answer.label, payload: payload),
                        correctAnswer: answer.value, options: choices.map(\.value), difficulty: difficulty)
    }

    private static func robotPrompt(_ kind: GameKind) -> String {
        kind == .codingLoop
            ? L.t("Which code takes 🤖 to ⭐?", no: "Hvilken kode tar 🤖 til ⭐?",
                  es: "¿Qué código lleva a 🤖 hasta ⭐?", pt: "Que código leva o 🤖 até à ⭐?")
            : L.t("Which arrows take 🤖 to ⭐?", no: "Hvilke piler tar 🤖 til ⭐?",
                  es: "¿Qué flechas llevan a 🤖 hasta ⭐?", pt: "Que setas levam o 🤖 até à ⭐?")
    }

    /// The cells a robot visits, or nil if it leaves the grid.
    nonisolated static func route(_ moves: [CodingMove], from start: CodingCell, size: Int) -> [CodingCell]? {
        var cell = start
        var cells: [CodingCell] = []
        for move in moves {
            cell = cell.moved(move)
            guard (0..<size).contains(cell.column), (0..<size).contains(cell.row) else { return nil }
            cells.append(cell)
        }
        return cells
    }

    /// Near-misses of a program: one arrow turned, one missing or extra, the order swapped,
    /// a loop count off by one.
    static func distractors(of program: CodingProgram) -> [CodingProgram] {
        var result: [CodingProgram] = []
        for (i, step) in program.enumerated() {
            // A loop that runs once too few or too many times.
            if step.times > 1 {
                for times in [step.times - 1, step.times + 1] {
                    var p = program
                    p[i] = CodingStep(step.moves, times: times)
                    result.append(p)
                }
            }
            // One arrow turned the other way or sideways.
            for (j, move) in step.moves.enumerated() {
                for turned in [move.opposite, move.turnedLeft, move.turnedRight] {
                    var moves = step.moves
                    moves[j] = turned
                    var p = program
                    p[i] = CodingStep(moves, times: step.times)
                    result.append(p)
                }
            }
            // Arrows inside a loop in the other order.
            if step.moves.count > 1 {
                var p = program
                p[i] = CodingStep(step.moves.reversed(), times: step.times)
                result.append(p)
            }
        }
        if program.count > 1 {
            // Steps in another order (same arrows, so it only fails when it bumps into a rock).
            result.append(Array(program.reversed()))
            for _ in 0..<4 { result.append(program.shuffled()) }
            // One step left out, or one repeated.
            for i in program.indices {
                var shorter = program
                shorter.remove(at: i)
                result.append(shorter)
            }
            if program.allSatisfy({ $0.times == 1 }) {
                var longer = program
                longer.append(program.last!)
                result.append(longer)
            }
        }
        return result.filter { !$0.isEmpty && $0 != program }
    }

    /// "→ → ↓" or "(→ ↓) ×3 →": shown after two misses and read by VoiceOver via `spoken`.
    static func label(for program: CodingProgram) -> String {
        program.map { step in
            let arrows = step.moves.map(\.glyph).joined(separator: " ")
            guard step.times > 1 else { return arrows }
            return step.moves.count > 1 ? "(\(arrows)) ×\(step.times)" : "\(arrows) ×\(step.times)"
        }.joined(separator: "  ")
    }

    static func spoken(_ program: CodingProgram) -> String {
        program.map { step in
            let words = step.moves.map(\.word).joined(separator: ", ")
            guard step.times > 1 else { return words }
            return L.t("\(step.times) times \(words)", no: "\(step.times) ganger \(words)",
                       es: "\(step.times) veces \(words)", pt: "\(step.times) vezes \(words)")
        }.joined(separator: ", ")
    }

    // MARK: - Symmetry

    /// Rows × columns of the left half.
    static func symmetrySize(age: Int, difficulty: ExerciseDifficulty) -> (rows: Int, half: Int) {
        if age <= 7 { return (4, difficulty == .challenge ? 3 : 2) }
        return (difficulty == .challenge ? 5 : 4, 3)
    }

    /// Paint colours (index into the view's palette, 1-based; 0 is an empty cell).
    static let paintCount = 5

    private static func symmetry(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let (rows, half) = symmetrySize(age: age, difficulty: difficulty)
        let colours = Array((1...paintCount).shuffled().prefix(difficulty.rawValue >= ExerciseDifficulty.harder.rawValue ? 2 : 1))
        var left: [[Int]] = []
        var correct: [[Int]] = []
        var wrong: [[[Int]]] = []
        while true {
            left = (0..<rows).map { _ in (0..<half).map { _ in Int.random(in: 0..<10) < 5 ? colours.randomElement()! : 0 } }
            let filled = left.joined().filter { $0 != 0 }.count
            guard (rows * half * 3 / 10...rows * half * 7 / 10).contains(filled) else { continue }
            correct = mirrored(left)
            guard correct != left else { continue }
            let used = Array(Set(left.joined()).subtracting([0]))
            // Not mirrored (copied across), upside down, one cell wrong.
            let copied = left
            let upsideDown = Array(correct.reversed())
            var oneOff = correct
            let r = Int.random(in: 0..<rows), c = Int.random(in: 0..<half)
            oneOff[r][c] = oneOff[r][c] == 0 ? used.randomElement()! : 0
            let pool: [[[Int]]] = switch difficulty {
            case .warmup, .normal: [copied, upsideDown]
            case .harder: [copied, oneOff]
            case .challenge: [upsideDown, oneOff].shuffled()
            }
            wrong = pool
            if Set([correct] + wrong).count == 3 { break }
        }

        let halves = ([correct] + wrong).shuffled()
        let choices = halves.indices.map { GameChoice(label: "🪞", value: $0 + 1) }
        let answer = choices[halves.firstIndex(of: correct)!]
        let prompt = L.t("Which picture finishes the mirror?", no: "Hvilket bilde fullfører speilet?",
                         es: "¿Qué dibujo completa el espejo?", pt: "Que desenho completa o espelho?")
        let payload = SymmetryPayload(left: left, halves: halves, choices: choices)
        return Exercise(game: GameSpec(kind: .symmetry, prompt: prompt, answerText: answer.label, payload: payload),
                        correctAnswer: answer.value, options: choices.map(\.value), difficulty: difficulty)
    }

    /// The left half seen in a mirror standing on its right edge.
    static func mirrored(_ left: [[Int]]) -> [[Int]] {
        left.map { Array($0.reversed()) }
    }
}

// MARK: - Model

nonisolated enum CodingMove: Int, Hashable, Sendable, CaseIterable {
    case up, right, down, left

    var dx: Int { self == .right ? 1 : self == .left ? -1 : 0 }
    var dy: Int { self == .down ? 1 : self == .up ? -1 : 0 }
    var opposite: CodingMove { CodingMove(rawValue: (rawValue + 2) % 4)! }
    var turnedRight: CodingMove { CodingMove(rawValue: (rawValue + 1) % 4)! }
    var turnedLeft: CodingMove { CodingMove(rawValue: (rawValue + 3) % 4)! }
    var glyph: String { ["↑", "→", "↓", "←"][rawValue] }
    var symbol: String { ["arrowshape.up.fill", "arrowshape.right.fill", "arrowshape.down.fill", "arrowshape.left.fill"][rawValue] }
    var word: String {
        switch self {
        case .up: L.t("up", no: "opp", es: "arriba", pt: "para cima")
        case .right: L.t("right", no: "høyre", es: "derecha", pt: "direita")
        case .down: L.t("down", no: "ned", es: "abajo", pt: "para baixo")
        case .left: L.t("left", no: "venstre", es: "izquierda", pt: "esquerda")
        }
    }
}

/// One instruction: its arrows, run `times` times (1 = a plain arrow, more = a loop).
nonisolated struct CodingStep: Hashable, Sendable {
    let moves: [CodingMove]
    let times: Int

    init(_ moves: [CodingMove], times: Int) {
        self.moves = moves
        self.times = times
    }

    init(_ move: CodingMove) {
        self.init([move], times: 1)
    }
}

typealias CodingProgram = [CodingStep]

extension Array where Element == CodingStep {
    /// Every single arrow the robot takes, loops unrolled.
    nonisolated var flattened: [CodingMove] {
        flatMap { step in (0..<step.times).flatMap { _ in step.moves } }
    }
}

nonisolated struct CodingCell: Hashable, Sendable {
    let column: Int
    let row: Int

    init(_ column: Int, _ row: Int) {
        self.column = column
        self.row = row
    }

    func moved(_ move: CodingMove) -> CodingCell {
        CodingCell(column + move.dx, row + move.dy)
    }
}

nonisolated struct CodingBoard: Hashable, Sendable {
    let size: Int
    let robot: CodingCell
    let star: CodingCell
    let rocks: Set<CodingCell>

    enum Outcome { case reachesStar, crashes, stopsElsewhere }

    /// Runs the program: crashes on a rock or off the grid, otherwise ends on the star or not.
    func run(_ program: CodingProgram) -> Outcome {
        guard let cells = CodingGames.route(program.flattened, from: robot, size: size) else { return .crashes }
        if cells.contains(where: rocks.contains) { return .crashes }
        return cells.last == star ? .reachesStar : .stopsElsewhere
    }
}

/// codingPath and codingLoop: the grid, and one program per choice (same order as `choices`).
nonisolated struct CodingGridPayload: GamePayload {
    let board: CodingBoard
    let programs: [CodingProgram]
    let choices: [GameChoice]
}

/// symmetry: the painted left half and one candidate right half per choice. 0 = empty, else a paint.
nonisolated struct SymmetryPayload: GamePayload {
    let left: [[Int]]
    let halves: [[[Int]]]
    let choices: [GameChoice]
}
