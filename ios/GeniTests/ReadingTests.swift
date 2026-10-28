import Foundation
import Testing
@testable import Geni

@MainActor
struct ReadingTests {
    @Test func storyStartsAtFirstEpisode() throws {
        let child = try profile(id: "reading-tests")
        #expect(ReadingContentService.textForToday(profile: child, date: "2026-10-25", history: []).id == "y1")
    }

    @Test func storyMovesOnTheDayAfterAnEpisodeIsFinished() throws {
        let child = try profile(id: "reading-tests")
        let history = [session(child, "y1", on: "2026-10-24", completed: true)]
        #expect(ReadingContentService.textForToday(profile: child, date: "2026-10-25", history: history).id == "y2")
    }

    @Test func episodeStaysPutForTheRestOfTheDay() throws {
        let child = try profile(id: "reading-tests")
        let history = [session(child, "y1", on: "2026-10-25", completed: true)]
        #expect(ReadingContentService.textForToday(profile: child, date: "2026-10-25", history: history).id == "y1")
    }

    @Test func unfinishedEpisodeIsOfferedAgain() throws {
        let child = try profile(id: "reading-tests")
        let history = [session(child, "y1", on: "2026-10-24", completed: false)]
        #expect(ReadingContentService.textForToday(profile: child, date: "2026-10-25", history: history).id == "y1")
    }

    @Test(arguments: [
        ("2026-10-25", "y2"),
        ("2026-10-26", "y1"),
        ("2026-10-27", "y4")
    ])
    func finishedStoryRepeatsInStableDailyOrder(date: String, expectedID: String) throws {
        let child = try profile(id: "reading-tests")
        let history = ["y1", "y2", "y3", "y4"].map { session(child, $0, on: "2026-10-01", completed: true) }
        #expect(ReadingContentService.textForToday(profile: child, date: date, history: history).id == expectedID)
    }

    @Test func everyEpisodeIsWrittenInEveryLanguage() {
        let texts = ReadingContentService.allTexts
        #expect(Set(texts.map(\.id)).count == texts.count)
        for text in texts {
            for value in [text.titleEN, text.titleNO, text.titleES, text.titlePT,
                          text.contentEN, text.contentNO, text.contentES, text.contentPT] {
                #expect(!value.isEmpty, "\(text.id)")
                #expect(!value.contains("  "), "\(text.id): double spaces break word highlighting")
            }
        }
    }

    @Test(arguments: [["I", "am", "a", "cat"], ["I"], ["a"], ["a", "a"]])
    func singleLetterWordsAreRecognized(words: [String]) {
        let service = SpeechRecognitionService()
        service.recognizedWords = words
        #expect(service.matchedWordCount(expected: words) == words.count)
        #expect(service.misreadIndices.isEmpty)
    }

    @Test func repeatedWordsMatchForward() {
        let service = SpeechRecognitionService()
        let words = ["the", "cat", "and", "the", "dog"]
        service.recognizedWords = words
        #expect(service.matchedWordCount(expected: words) == words.count)
        #expect(service.misreadIndices.isEmpty)
    }

    @Test func cumulativeTranscriptDoesNotConsumeRepeatedWordsTwice() {
        let service = SpeechRecognitionService()
        let expected = ["the", "cat", "and", "the", "dog"]
        service.recognizedWords = ["the", "cat", "and"]
        #expect(service.matchedWordCount(expected: expected) == 3)
        #expect(service.matchedWordCount(expected: expected, startFrom: 3) == 3)
        service.recognizedWords = expected
        #expect(service.matchedWordCount(expected: expected, startFrom: 3) == 5)
        #expect(service.misreadIndices.isEmpty)
    }

    @Test func partialWordsWaitForTheFullWord() {
        let service = SpeechRecognitionService()
        service.recognizedWords = ["the", "ca"]
        #expect(service.matchedWordCount(expected: ["the", "cat"]) == 1)
        service.recognizedWords = ["the", "cat"]
        #expect(service.matchedWordCount(expected: ["the", "cat"], startFrom: 1) == 2)
        #expect(service.misreadIndices.isEmpty)
    }

    @Test func transcriptResetAllowsTheSameWordInANewSegment() {
        let service = SpeechRecognitionService()
        service.recognizedWords = ["the"]
        #expect(service.matchedWordCount(expected: ["the", "the"]) == 1)
        service.resetTranscript()
        service.recognizedWords = ["the"]
        #expect(service.matchedWordCount(expected: ["the", "the"], startFrom: 1) == 2)
    }

    @Test func readToMeResumeRestartsHighlightingAndCompletion() async throws {
        let vm = makeViewModel(mode: .readToMe)
        let speech = ReadingTestSpeechService()
        vm.speechService = speech
        defer { vm.stop() }
        vm.start()
        vm.pause()
        speech.currentWordRange = NSRange(location: 6, length: 5)
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.currentWordIndex == 0)
        vm.resume()
        let highlighted = try await waitUntil { vm.currentWordIndex == 1 }
        #expect(highlighted)
        speech.didFinishSpeaking = true
        let completed = try await waitUntil { vm.isCompleted }
        #expect(completed)
        #expect(speech.speakCalls == 1)
    }

    @Test func listenResumeRestartsMatchingAndCompletion() async throws {
        let vm = makeViewModel(mode: .listenToMeRead)
        let recognition = ReadingTestRecognitionService()
        vm.recognitionService = recognition
        defer { vm.stop() }
        vm.start()
        let started = try await waitUntil { recognition.isListening }
        try #require(started)
        recognition.recognizedWords = ["hello"]
        let firstMatched = try await waitUntil { vm.matchedWordCount == 1 }
        try #require(firstMatched)
        vm.pause()
        recognition.recognizedWords = ["world"]
        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.matchedWordCount == 1)
        vm.resume()
        let resumed = try await waitUntil { recognition.startCalls == 2 }
        try #require(resumed)
        recognition.recognizedWords = ["world"]
        let completed = try await waitUntil { vm.isCompleted }
        #expect(completed)
        #expect(vm.matchedWordCount == 2)
    }

    @Test(arguments: [true, false])
    func permissionResponseAfterStopIsIgnored(granted: Bool) async throws {
        let vm = makeViewModel(mode: .listenToMeRead)
        let recognition = ReadingTestRecognitionService()
        recognition.holdPermission = true
        vm.recognitionService = recognition
        defer { vm.stop() }
        vm.start()
        let requested = try await waitUntil { recognition.pendingPermission != nil }
        try #require(requested)
        vm.stop()
        recognition.resolvePermission(granted)
        try await Task.sleep(for: .milliseconds(200))
        #expect(recognition.startCalls == 0)
        #expect(!recognition.isListening)
        #expect(!vm.isPlaying)
        #expect(!vm.showFeedback)
    }

    @Test func oldPermissionResponseCannotStartANewerSession() async throws {
        let vm = makeViewModel(mode: .listenToMeRead)
        let recognition = ReadingTestRecognitionService()
        recognition.holdPermission = true
        vm.recognitionService = recognition
        defer { vm.stop() }
        vm.start()
        let requested = try await waitUntil { recognition.pendingPermission != nil }
        try #require(requested)
        vm.pause()
        recognition.holdPermission = false
        vm.resume()
        let resumed = try await waitUntil { recognition.startCalls == 1 }
        try #require(resumed)
        recognition.resolvePermission(true)
        try await Task.sleep(for: .milliseconds(200))
        #expect(recognition.startCalls == 1)
    }

    @Test(arguments: [false, true])
    func recognitionFailureCannotAutoComplete(runtimeFailure: Bool) async throws {
        let vm = makeViewModel(mode: .listenToMeRead, content: "hello")
        let recognition = ReadingTestRecognitionService()
        recognition.isAvailable = runtimeFailure
        vm.recognitionService = recognition
        defer { vm.stop() }
        vm.start()
        if runtimeFailure {
            let started = try await waitUntil { recognition.isListening }
            try #require(started)
            recognition.error = L.s(.audioEngineStartError)
        }
        let paused = try await waitUntil { vm.isPaused }
        #expect(paused)
        // Past the original timeout plus completion delay for a one-word passage.
        try await Task.sleep(for: .seconds(7))
        #expect(vm.matchedWordCount == 0)
        #expect(!vm.isCompleted)
        #expect(vm.coinsEarned == 0)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.showFeedback)
        #expect(vm.feedbackTone == .error)
        #expect(!vm.feedbackMessage.isEmpty)
        recognition.isAvailable = true
        recognition.error = nil
        vm.resume()
        let retried = try await waitUntil { recognition.isListening }
        #expect(retried)
        #expect(!vm.showFeedback)
    }

    private func session(_ child: ChildProfile, _ textId: String, on date: String, completed: Bool) -> ReadingSession {
        var session = ReadingSession(childId: child.id, date: date, readingTextId: textId, mode: .readByMyself,
                                     targetTimeSeconds: 180)
        if completed { session.complete() }
        return session
    }

    private func profile(id: String) throws -> ChildProfile {
        let child = ChildProfile(nickname: "Reader", age: 6, avatarId: "lion")
        let data = try JSONEncoder().encode(child)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["id"] = id
        return try JSONDecoder().decode(ChildProfile.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func makeViewModel(mode: ReadingMode, content: String = "hello world") -> ReadingViewModel {
        let text = ReadingText(
            id: "reading-test", titleEN: "Test", titleNO: "Test", titleES: "Test", titlePT: "Test",
            contentEN: content, contentNO: content, contentES: content, contentPT: content,
            ageGroup: .young
        )
        return ReadingViewModel(
            profile: ChildProfile(nickname: "Reader", age: 6, avatarId: "lion"),
            readingText: text, mode: mode, date: "2026-10-25"
        )
    }

    private func waitUntil(_ predicate: () -> Bool) async throws -> Bool {
        for _ in 0..<150 {
            if predicate() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return predicate()
    }
}

@MainActor
private final class ReadingTestSpeechService: SpeechService {
    var speakCalls = 0

    override func speak(_ text: String, rate: Float) {
        speakCalls += 1
        didFinishSpeaking = false
    }

    override func pause() {}
    override func resume() {}
    override func stop() {}
}

@MainActor
private final class ReadingTestRecognitionService: SpeechRecognitionService {
    var holdPermission = false
    var pendingPermission: CheckedContinuation<Bool, Never>?
    var startCalls = 0

    override init() {
        super.init()
        isAvailable = true
    }

    override func requestPermissions() async -> Bool {
        if holdPermission {
            return await withCheckedContinuation { pendingPermission = $0 }
        }
        return true
    }

    func resolvePermission(_ granted: Bool) {
        pendingPermission?.resume(returning: granted)
        pendingPermission = nil
    }

    override func startListening() {
        startCalls += 1
        isListening = isAvailable && error == nil
    }

    override func stopListening(clearTranscript: Bool = true) {
        isListening = false
        if clearTranscript { resetTranscript() }
    }
}
