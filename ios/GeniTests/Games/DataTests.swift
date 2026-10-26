import Foundation
import Testing
@testable import Geni

/// Tally charts, bar charts and estimation: ages 7–10.
@MainActor
@Suite(.serialized)
struct DataTests {
    private static let kinds: [GameKind] = [.tallyChart, .barChart, .estimate]
    private static let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]

    private func forEvery(_ body: (GameKind, Int, ExerciseDifficulty, Exercise, GameSpec) -> Void) {
        for kind in Self.kinds {
            for age in kind.ages {
                for difficulty in Self.difficulties {
                    for _ in 0..<100 {
                        let exercise = DataGames.make(kind, age: age, difficulty: difficulty)
                        guard let spec = exercise.game else {
                            Issue.record("\(kind) has no game spec")
                            continue
                        }
                        body(kind, age, difficulty, exercise, spec)
                    }
                }
            }
        }
    }

    private func choices(_ spec: GameSpec) -> [GameChoice] {
        if let p = spec.payload as? TallyPayload { return p.choices }
        if let p = spec.payload as? BarPayload { return p.choices }
        if let p = spec.payload as? EstimatePayload { return p.choices }
        return []
    }

    @Test func everyExerciseIsWellFormed() {
        forEvery { kind, age, _, exercise, spec in
            #expect(exercise.format == .game)
            #expect(spec.kind == kind)
            #expect(!spec.prompt.isEmpty)
            #expect(!spec.answerText.isEmpty)
            let options = exercise.options
            #expect(Set(options).count == options.count)
            #expect(options.contains(exercise.correctAnswer))
            #expect(options.count >= 2 && options.count <= 4)
            #expect(options == choices(spec).map(\.value))
            #expect(Set(choices(spec).map(\.label)).count == options.count)
            #expect(choices(spec).first { $0.value == exercise.correctAnswer }?.label == spec.answerText)
            if age <= 5 {
                for symbol in ["+", "=", "−", "×", "÷"] { #expect(!spec.prompt.contains(symbol)) }
            }
        }
    }

    @Test func tallyChartAnswersMatchTheMarks() {
        var sawMost = false, sawCount = false
        forEvery { kind, _, _, exercise, spec in
            guard kind == .tallyChart, let p = spec.payload as? TallyPayload else { return }
            #expect(p.rows.count == 3)
            #expect(Set(p.rows.map(\.emoji)).count == 3)
            #expect(Set(p.rows.map(\.count)).count == 3)
            #expect(p.rows.allSatisfy { (1...15).contains($0.count) })
            if p.choices.allSatisfy({ p.rows.map(\.emoji).contains($0.label) }) {
                sawMost = true
                #expect(p.choices.count == 3)
                let best = p.rows.max { $0.count < $1.count }
                #expect(p.rows[exercise.correctAnswer].emoji == best?.emoji)
            } else {
                sawCount = true
                let row = p.rows.first { spec.prompt.contains($0.emoji) }
                #expect(row?.count == exercise.correctAnswer)
                #expect(p.choices.allSatisfy { (1...15).contains($0.value) })
            }
        }
        #expect(sawMost && sawCount)
    }

    @Test func barChartAnswersMatchTheBars() {
        var seen = Set<String>()
        forEvery { kind, age, _, exercise, spec in
            guard kind == .barChart, let p = spec.payload as? BarPayload else { return }
            #expect((3...4).contains(p.bars.count))
            #expect(Set(p.bars.map(\.emoji)).count == p.bars.count)
            #expect(Set(p.bars.map(\.value)).count == p.bars.count)
            #expect(p.bars.allSatisfy { (1...p.axisMax).contains($0.value) })
            #expect([6, 8, 10].contains(p.axisMax))
            if p.choices.allSatisfy({ p.bars.map(\.emoji).contains($0.label) }) {
                seen.insert("tallest")
                #expect(p.bars[exercise.correctAnswer].value == p.bars.map(\.value).max())
            } else if spec.prompt.contains(" more ") || spec.prompt.contains("flere") ||
                        spec.prompt.contains("más") || spec.prompt.contains("mais") {
                seen.insert("difference")
                let found = p.bars.filter { spec.prompt.contains($0.emoji) }
                #expect(found.count == 2)
                let ordered = found.sorted {
                    (spec.prompt.range(of: $0.emoji)?.lowerBound ?? spec.prompt.endIndex) <
                        (spec.prompt.range(of: $1.emoji)?.lowerBound ?? spec.prompt.endIndex)
                }
                #expect(ordered[0].value > ordered[1].value)
                let values = found.map(\.value).sorted(by: >)
                #expect(values[0] - values[1] == exercise.correctAnswer)
                #expect(age >= 8)
            } else {
                seen.insert("count")
                let bar = p.bars.first { spec.prompt.contains($0.emoji) }
                #expect(bar?.value == exercise.correctAnswer)
            }
            #expect(p.choices.allSatisfy { $0.value >= 0 })
        }
        #expect(seen == ["tallest", "difference", "count"])
    }

    @Test func estimatesAreFair() {
        var sawSum = false, sawJar = false
        forEvery { kind, age, _, exercise, spec in
            guard kind == .estimate, let p = spec.payload as? EstimatePayload else { return }
            #expect(age >= 9)
            let values = p.choices.map(\.value).sorted()
            if let expression = p.expression {
                sawSum = true
                let parts = expression.split(separator: " ").map(String.init)
                #expect(parts.count == 3)
                let a = Int(parts[0]) ?? 0, b = Int(parts[2]) ?? 0
                let exact = parts[1] == "+" ? a + b : a - b
                #expect(a > 0 && b > 0 && exact > 0)
                // The right choice is the nearest and every other is at least 3× further away.
                let nearest = values.min { abs($0 - exact) < abs($1 - exact) }
                #expect(nearest == exercise.correctAnswer)
                let gap = abs(exercise.correctAnswer - exact)
                for v in values where v != exercise.correctAnswer {
                    #expect(abs(v - exact) >= max(3 * gap, 10))
                }
                #expect(values.allSatisfy { $0 > 0 })
                #expect(zip(values, values.dropFirst()).allSatisfy { $1 - $0 >= 20 })
            } else {
                sawJar = true
                let count = p.beans.count
                #expect((18...55).contains(count))
                #expect(p.beans.allSatisfy { (0...Double(EstimatePayload.jarColumns)).contains($0.x) && $0.y > 0 })
                let nearest = values.min { abs($0 - count) < abs($1 - count) }
                #expect(nearest == exercise.correctAnswer)
                let gap = abs(exercise.correctAnswer - count)
                for v in values where v != exercise.correctAnswer {
                    #expect(abs(v - count) >= 3 * gap)
                    #expect(Double(max(v, exercise.correctAnswer)) / Double(min(v, exercise.correctAnswer)) >= 1.9)
                }
            }
        }
        #expect(sawSum && sawJar)
    }

    @Test(arguments: AppLanguage.allCases)
    func allLanguagesProduceText(language: AppLanguage) {
        let key = "geni_app_language"
        let saved = UserDefaults.standard.string(forKey: key)
        L.selectedLanguage = language
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
        }
        for kind in Self.kinds {
            for age in kind.ages {
                for difficulty in Self.difficulties {
                    for _ in 0..<10 {
                        let spec = DataGames.make(kind, age: age, difficulty: difficulty).game
                        #expect(!(spec?.prompt.isEmpty ?? true))
                        #expect(!(spec?.answerText.isEmpty ?? true))
                    }
                }
            }
        }
    }
}
