import Foundation
import Testing
@testable import Geni

/// Ages 4–5 hear every question; spoken text uses words, never the on-screen symbols.
@MainActor
@Suite(.serialized)
struct SpokenPromptTests {
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

    @Test(arguments: AppLanguage.allCases)
    func everyYoungExerciseHasASpokenPrompt(language: AppLanguage) {
        withLanguage(language) {
            for age in [4, 5] {
                let profile = ChildProfile(nickname: "Mo", age: age, avatarId: "lion")
                for _ in 0..<50 {
                    var chapters = [ExerciseGenerator.generateChapter(profile: profile)]
                    for operation in MathOperation.allCases {
                        chapters.append(ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: operation))
                    }
                    for exercise in chapters.joined() {
                        let spoken = exercise.spokenPrompt
                        #expect(spoken != nil, "no spoken prompt for \(exercise.format) at age \(age)")
                        for symbol in ["+", "=", "\u{2212}", "\u{00D7}", "\u{00F7}", "%@"] {
                            #expect(spoken?.contains(symbol) == false, "\(symbol) in \(spoken ?? "")")
                        }
                    }
                }
            }
        }
    }

    @Test func sumsAreReadAsWords() {
        withLanguage(.norwegian) {
            let sum = Exercise(operand1: 3, operand2: 2, operation: .addition, difficulty: .warmup, format: .solveResult)
            #expect(sum.spokenPrompt == "Hva er 3 pluss 2?")
        }
        withLanguage(.spanish) {
            let sum = Exercise(operand1: 3, operand2: 2, operation: .addition, difficulty: .warmup, format: .solveResult)
            #expect(sum.spokenPrompt == "\u{00BF}Cu\u{00E1}nto es 3 m\u{00E1}s 2?")
        }
        withLanguage(.english) {
            let count = Exercise(emojiFormat: .countingObjects, emojiSymbol: "🍎", count: 3, difficulty: .warmup)
            #expect(count.spokenPrompt == "How many?")
        }
    }
}
