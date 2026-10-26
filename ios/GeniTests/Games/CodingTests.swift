import Foundation
import Testing
@testable import Geni

@MainActor
@Suite(.serialized)
struct CodingTests {
    private let kinds: [GameKind] = [.codingPath, .codingLoop, .symmetry]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    private func withLanguage(_ language: AppLanguage, _ body: () -> Void) {
        let key = "geni_app_language"
        let saved = UserDefaults.standard.string(forKey: key)
        L.selectedLanguage = language
        body()
        if let saved {
            UserDefaults.standard.set(saved, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Every kind × age × difficulty, ~100 each.
    private func forEachExercise(_ body: (GameKind, Int, ExerciseDifficulty, Exercise) -> Void) {
        for kind in kinds {
            for age in kind.ages {
                for difficulty in difficulties {
                    for _ in 0..<100 {
                        body(kind, age, difficulty, CodingGames.make(kind, age: age, difficulty: difficulty))
                    }
                }
            }
        }
    }

    private func choices(of exercise: Exercise) -> [GameChoice] {
        switch exercise.game?.payload {
        case let p as CodingGridPayload: return p.choices
        case let p as SymmetryPayload: return p.choices
        default: return []
        }
    }

    @Test func everyGameIsWellFormed() {
        forEachExercise { kind, age, difficulty, exercise in
            let tag = "\(kind) age \(age) \(difficulty)"
            #expect(exercise.format == .game, "\(tag)")
            #expect(exercise.game?.kind == kind, "\(tag)")
            #expect(exercise.difficulty == difficulty, "\(tag)")
            #expect(exercise.game?.prompt.isEmpty == false, "\(tag)")
            #expect(exercise.game?.answerText.isEmpty == false, "\(tag)")
            let tiles = choices(of: exercise)
            #expect(tiles.count == 3, "\(tag)")
            #expect(tiles.map(\.value) == exercise.options, "\(tag)")
            #expect(Set(exercise.options).count == exercise.options.count, "\(tag)")
            #expect(exercise.options.contains(exercise.correctAnswer), "\(tag)")
            #expect(exercise.options.allSatisfy { (1...3).contains($0) }, "\(tag)")
            #expect(tiles.first { $0.value == exercise.correctAnswer }?.label == exercise.game?.answerText, "\(tag)")
        }
    }

    @Test func exactlyOneProgramReachesTheStar() {
        forEachExercise { kind, age, difficulty, exercise in
            guard let p = exercise.game?.payload as? CodingGridPayload else {
                #expect(kind == .symmetry, "\(kind) needs a grid")
                return
            }
            let tag = "\(kind) age \(age) \(difficulty)"
            let board = p.board
            #expect(board.size == CodingGames.gridSize(kind, age: age, difficulty: difficulty), "\(tag)")
            #expect(p.programs.count == p.choices.count, "\(tag)")
            #expect(board.robot != board.star, "\(tag)")
            #expect(!board.rocks.contains(board.robot) && !board.rocks.contains(board.star), "\(tag)")
            #expect(board.rocks.count == CodingGames.rockCount(kind, age: age, difficulty: difficulty), "\(tag)")
            for cell in [board.robot, board.star] + Array(board.rocks) {
                #expect((0..<board.size).contains(cell.column) && (0..<board.size).contains(cell.row), "\(tag)")
            }
            let winners = p.choices.indices.filter { simulate(p.programs[$0], on: board) }
            #expect(winners.count == 1, "\(tag): \(p.programs.map(CodingGames.label(for:)))")
            if let winner = winners.first {
                #expect(p.choices[winner].value == exercise.correctAnswer, "\(tag)")
                let moves = p.programs[winner].flatMap { step in (0..<step.times).flatMap { _ in step.moves } }
                // The right answer is a shortest route.
                let distance = abs(board.star.column - board.robot.column) + abs(board.star.row - board.robot.row)
                #expect(moves.count == distance, "\(tag)")
                if kind == .codingPath {
                    #expect(CodingGames.pathLength(age: age, difficulty: difficulty).contains(moves.count), "\(tag)")
                }
            }
            // Distinct-looking programs.
            #expect(Set(p.programs.map(CodingGames.label(for:))).count == p.programs.count, "\(tag)")
            for program in p.programs {
                #expect(!program.isEmpty && program.allSatisfy { $0.times >= 1 && !$0.moves.isEmpty }, "\(tag)")
                if kind == .codingPath {
                    #expect(program.allSatisfy { $0.times == 1 && $0.moves.count == 1 }, "\(tag): arrows only")
                }
            }
            if kind == .codingLoop {
                let correct = p.programs[p.choices.firstIndex { $0.value == exercise.correctAnswer }!]
                #expect(correct.contains { $0.times > 1 }, "\(tag): the answer uses a loop")
                #expect(correct.allSatisfy { $0.times <= 4 }, "\(tag)")
            }
        }
    }

    /// Independent of `CodingBoard.run`: step cell by cell; off the grid or onto a rock fails.
    private func simulate(_ program: CodingProgram, on board: CodingBoard) -> Bool {
        var column = board.robot.column, row = board.robot.row
        for step in program {
            for _ in 0..<step.times {
                for move in step.moves {
                    switch move {
                    case .up: row -= 1
                    case .down: row += 1
                    case .left: column -= 1
                    case .right: column += 1
                    }
                    guard (0..<board.size).contains(column), (0..<board.size).contains(row),
                          !board.rocks.contains(CodingCell(column, row)) else { return false }
                }
            }
        }
        return CodingCell(column, row) == board.star
    }

    @Test func exactlyOneHalfFinishesTheMirror() {
        forEachExercise { kind, age, difficulty, exercise in
            guard kind == .symmetry else { return }
            let tag = "age \(age) \(difficulty)"
            guard let p = exercise.game?.payload as? SymmetryPayload else {
                Issue.record("\(tag): no symmetry payload")
                return
            }
            let size = CodingGames.symmetrySize(age: age, difficulty: difficulty)
            #expect(p.left.count == size.rows && p.left.allSatisfy { $0.count == size.half }, "\(tag)")
            #expect(p.halves.count == p.choices.count, "\(tag)")
            #expect(Set(p.halves).count == p.halves.count, "\(tag)")
            let mirror = p.left.map { Array($0.reversed()) }
            let matches = p.choices.indices.filter { p.halves[$0] == mirror }
            #expect(matches.count == 1, "\(tag)")
            #expect(matches.first.map { p.choices[$0].value } == exercise.correctAnswer, "\(tag)")
            let paints = Set(p.left.joined()).subtracting([0])
            #expect(!paints.isEmpty && paints.allSatisfy { (1...CodingGames.paintCount).contains($0) }, "\(tag)")
            #expect(paints.count <= (difficulty.rawValue >= ExerciseDifficulty.harder.rawValue ? 2 : 1), "\(tag)")
            #expect(p.left != mirror, "\(tag): the half must not look the same mirrored")
            for half in p.halves {
                #expect(half.count == size.rows && half.allSatisfy { $0.count == size.half }, "\(tag)")
                #expect(Set(half.joined()).subtracting([0]).isSubset(of: paints), "\(tag)")
            }
        }
    }

    @Test func distractorsNeverRepeatTheProgram() {
        let program: CodingProgram = [CodingStep([.right, .down], times: 3)]
        let others = CodingGames.distractors(of: program)
        #expect(!others.isEmpty)
        #expect(!others.contains(program))
        #expect(others.contains([CodingStep([.right, .down], times: 2)]))
        #expect(others.contains([CodingStep([.down, .right], times: 3)]))
    }

    @Test func boardRunCatchesRocksAndEdges() {
        let board = CodingBoard(size: 4, robot: CodingCell(0, 0), star: CodingCell(2, 1), rocks: [CodingCell(1, 0)])
        #expect(board.run([CodingStep(.down), CodingStep([.right], times: 2)]) == .reachesStar)
        #expect(board.run([CodingStep([.right], times: 2), CodingStep(.down)]) == .crashes)
        #expect(board.run([CodingStep(.up)]) == .crashes)
        #expect(board.run([CodingStep(.down), CodingStep(.right)]) == .stopsElsewhere)
    }

    @Test func fallbackIsDeterministicAndHasExactlyOneValidProgram() throws {
        for kind in [GameKind.codingPath, .codingLoop] {
            for age in kind.ages {
                for difficulty in difficulties {
                    let exercise = CodingGames.fallbackRobotExercise(kind, age: age, difficulty: difficulty)
                    let repeatExercise = CodingGames.fallbackRobotExercise(kind, age: age, difficulty: difficulty)
                    let payload = try #require(exercise.game?.payload as? CodingGridPayload)
                    let repeated = try #require(repeatExercise.game?.payload as? CodingGridPayload)
                    #expect(payload.board == repeated.board)
                    #expect(payload.programs == repeated.programs)
                    #expect(exercise.correctAnswer == repeatExercise.correctAnswer)
                    #expect(payload.board.size == CodingGames.gridSize(kind, age: age, difficulty: difficulty))
                    #expect(payload.board.rocks.count == CodingGames.rockCount(kind, age: age, difficulty: difficulty))
                    let winners = payload.programs.indices.filter { simulate(payload.programs[$0], on: payload.board) }
                    #expect(winners.count == 1)
                    let winner = try #require(winners.first)
                    #expect(payload.choices[winner].value == exercise.correctAnswer)
                    #expect(payload.choices[winner].label == exercise.game?.answerText)
                    #expect(exercise.options == payload.choices.map(\.value))
                    #expect(Set(payload.programs).count == 3)
                    if kind == .codingPath {
                        #expect(CodingGames.pathLength(age: age, difficulty: difficulty).contains(payload.programs[winner].flattened.count))
                    } else {
                        #expect(payload.programs[winner].contains { $0.times > 1 })
                    }
                }
            }
        }
    }

    @Test func allLanguagesHaveText() {
        for language in AppLanguage.allCases {
            withLanguage(language) {
                for kind in kinds {
                    let exercise = CodingGames.make(kind, age: kind.ages.lowerBound, difficulty: .normal)
                    #expect(exercise.game?.prompt.isEmpty == false, "\(kind) \(language)")
                    #expect(exercise.game?.answerText.isEmpty == false, "\(kind) \(language)")
                    if let p = exercise.game?.payload as? CodingGridPayload {
                        #expect(p.programs.allSatisfy { !CodingGames.spoken($0).isEmpty }, "\(kind) \(language)")
                    }
                }
                #expect(CodingMove.allCases.allSatisfy { !$0.word.isEmpty })
            }
        }
    }
}
