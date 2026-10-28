import Foundation
import Testing
@testable import Geni

/// Everything Geni says out loud, for `scripts/voice/record.mjs` to record. Runs only when asked:
/// `TEST_RUNNER_GENI_VOICE_CATALOG=/tmp/geni-voice-catalog.json scripts/geni-build.sh test GeniTests/VoiceCatalogTests`
@MainActor
@Suite(.serialized)
struct VoiceCatalogTests {
    nonisolated private static let output = ProcessInfo.processInfo.environment["GENI_VOICE_CATALOG"]
    private let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private let chapterTypes: [ChapterType] = [.daily, .timeAttack, .perfectRun, .boss, .streak]

    @Test(.enabled(if: output != nil))
    func exportCatalog() throws {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }

        var reading: [[String: String]] = []
        var pieces: [[String: String]] = []
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            let lang = L.speechLocaleIdentifier
            for text in ReadingContentService.allTexts {
                reading.append(["lang": lang, "key": VoiceLibrary.key(text.content), "text": text.content,
                                "id": text.id, "age": text.ageGroup.rawValue])
            }
            // Every number a young question can use, even ones the sampling happened to miss.
            let numbers = (0...100).flatMap { VoiceLibrary.pieces(of: String($0)) }
            var seen = Set<String>()
            for piece in youngPrompts().sorted().flatMap(VoiceLibrary.pieces(of:)) + numbers where seen.insert(piece.key).inserted {
                pieces.append(["lang": lang, "key": piece.key, "text": piece.text])
            }
        }

        let catalog: [String: Any] = ["reading": reading, "pieces": pieces]
        let data = try JSONSerialization.data(withJSONObject: catalog, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: try #require(Self.output)))
    }

    /// Ages 4–5 hear every question. Generation is random, so sample until 500 rounds in a row add nothing new.
    private func youngPrompts() -> Set<String> {
        var found = Set<String>()
        var quietRounds = 0
        var rounds = 0
        while quietRounds < 500 && rounds < 20_000 {
            let before = found.count
            for age in [4, 5] {
                var profile = ChildProfile(nickname: "Voice", age: age, avatarId: "lion")
                profile.operationsEnabled = MathOperation.allCases
                var exercises = chapterTypes.flatMap { ExerciseGenerator.generateChapter(profile: profile, chapterType: $0) }
                exercises += MathOperation.allCases.flatMap { ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: $0) }
                exercises += MathTopic.allCases.flatMap { ExerciseGenerator.generateTopicChapter(profile: profile, topic: $0) }
                for kind in GameKind.allCases where kind.ages.contains(age) {
                    exercises += difficulties.map { GameFactory.make(kind, age: age, difficulty: $0) }
                }
                found.formUnion(exercises.compactMap(\.spokenPrompt))
            }
            quietRounds = found.count == before ? quietRounds + 1 : 0
            rounds += 1
        }
        return found
    }
}
