import Foundation
import Testing
@testable import Geni

/// The recorded voice must cover everything Geni reads aloud. If these fail after changing a reading text or a
/// spoken question, record again: see scripts/voice/record.mjs.
@MainActor
@Suite(.serialized)
struct VoiceLibraryTests {
    @Test func questionsSplitAtTheirNumbers() {
        #expect(VoiceLibrary.pieces(of: "9 plus 5 is 13. True or false?").map(\.text)
                == ["9", "plus", "5", "is", "13", "True or false?"])
        #expect(VoiceLibrary.pieces(of: "¿Cuánto es 5 más 3?").map(\.text) == ["¿Cuánto es", "5", "más", "3"])
        #expect(VoiceLibrary.pieces(of: "Which has more?").map(\.text) == ["Which has more?"])
    }

    @Test func keysIgnoreCaseAndPunctuation() {
        #expect(VoiceLibrary.key("What plus") == VoiceLibrary.key("what plus"))
        #expect(VoiceLibrary.key("«Herbert er borte», sa hun.") == "herbert er borte sa hun")
    }

    @Test(arguments: AppLanguage.allCases)
    func everyReadingTextIsRecordedWithWordTimings(language: AppLanguage) {
        withLanguage(language) {
            for text in ReadingContentService.allTexts {
                let clips = VoiceLibrary.clips(for: text.content, language: L.speechLocaleIdentifier)
                #expect(clips?.count == 1, "\(text.id) \(language) is not recorded")
                let starts = clips?.first?.wordStartsMs ?? []
                #expect(starts.count == text.words.count, "\(text.id) \(language) word timings")
                #expect(starts == starts.sorted(), "\(text.id) \(language) word timings out of order")
            }
        }
    }

    @Test(arguments: AppLanguage.allCases)
    func everyYoungQuestionIsRecorded(language: AppLanguage) {
        withLanguage(language) {
            for age in [4, 5] {
                var profile = ChildProfile(nickname: "Voice", age: age, avatarId: "lion")
                profile.operationsEnabled = MathOperation.allCases
                for _ in 0..<20 {
                    var exercises = ExerciseGenerator.generateChapter(profile: profile)
                    exercises += MathOperation.allCases.flatMap { ExerciseGenerator.generateSpotlightChapter(profile: profile, operation: $0) }
                    exercises += MathTopic.allCases.flatMap { ExerciseGenerator.generateTopicChapter(profile: profile, topic: $0) }
                    for kind in GameKind.allCases where kind.ages.contains(age) {
                        exercises += [ExerciseDifficulty.warmup, .normal, .harder, .challenge].map {
                            GameFactory.make(kind, age: age, difficulty: $0)
                        }
                    }
                    for prompt in exercises.compactMap(\.spokenPrompt) {
                        #expect(VoiceLibrary.clips(for: prompt, language: L.speechLocaleIdentifier) != nil,
                                "not recorded: \(prompt)")
                    }
                }
            }
        }
    }

    @Test func recordedReadingMovesTheWordHighlight() async throws {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        L.selectedLanguage = .english
        let text = try #require(ReadingContentService.allTexts.first).content
        let speech = SpeechService()
        speech.speak(text)
        defer { speech.stop() }
        try await Task.sleep(for: .seconds(3))
        let location = try #require(speech.currentWordRange?.location)
        #expect(location > 0 && speech.isSpeaking)
    }

    @Test func joinedQuestionPlaysToTheEnd() async throws {
        let original = L.selectedLanguage
        defer { L.selectedLanguage = original }
        L.selectedLanguage = .spanish
        let prompt = "¿Cuánto es 5 menos 3?"
        #expect(VoiceLibrary.clips(for: prompt, language: "es-ES")?.count == 4)
        let speech = SpeechService()
        speech.speak(prompt)
        for _ in 0..<100 where !speech.didFinishSpeaking {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(speech.didFinishSpeaking && !speech.isSpeaking)
    }

    private func withLanguage(_ language: AppLanguage, _ body: () -> Void) {
        let original = L.selectedLanguage
        L.selectedLanguage = language
        body()
        L.selectedLanguage = original
    }
}
