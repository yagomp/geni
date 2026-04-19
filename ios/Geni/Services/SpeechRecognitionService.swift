import Speech
import AVFoundation

@Observable
@MainActor
class SpeechRecognitionService {
    var recognizedText: String = ""
    var recognizedWords: [String] = []
    var isListening: Bool = false
    var isAvailable: Bool = false
    var error: String?
    var transcriptVersion: Int = 0
    var lastTranscriptUpdateAt: Date?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    init() {
        let locale = Locale(identifier: L.speechLocaleIdentifier)
        recognizer = SFSpeechRecognizer(locale: locale)
        isAvailable = recognizer?.isAvailable ?? false
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let audioStatus = await AVAudioApplication.requestRecordPermission()

        return speechStatus == .authorized && audioStatus
    }

    func startListening() {
        error = nil
        let locale = Locale(identifier: L.speechLocaleIdentifier)
        recognizer = SFSpeechRecognizer(locale: locale)
        isAvailable = recognizer?.isAvailable ?? false

        guard let recognizer, recognizer.isAvailable else {
            error = L.s(.speechRecognitionUnavailable)
            return
        }

        stopListening(clearTranscript: false)

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = L.s(.audioSessionError)
            return
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, err in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.updateTranscript(result.bestTranscription.formattedString)
                }
                if result?.isFinal == true {
                    // Recognition ended naturally — restart without clearing progress.
                    self.stopListening(clearTranscript: false)
                    self.startListening()
                } else if err != nil {
                    self.stopListening(clearTranscript: false)
                    if self.isAvailable {
                        self.startListening()
                    }
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isListening = true
        } catch {
            self.error = L.s(.audioEngineStartError)
            stopListening()
        }
    }

    func stopListening(clearTranscript: Bool = true) {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        if clearTranscript {
            resetTranscript()
        }
    }

    func resetTranscript(clearMisreads: Bool = false) {
        recognizedWords = []
        recognizedText = ""
        lastTranscriptUpdateAt = nil
        transcriptVersion += 1
        if clearMisreads {
            misreadIndices.removeAll()
        }
    }

    var misreadIndices: Set<Int> = []

    func matchedWordCount(expected: [String], startFrom: Int = 0) -> Int {
        let cleanExpected = expected.map { normalizedWord($0) }
        let cleanRecognized = recognizedWords.map { normalizedWord($0) }.filter { !$0.isEmpty }
        var matched = startFrom

        misreadIndices = misreadIndices.filter { $0 < cleanExpected.count }

        for recognized in cleanRecognized {
            if isIgnorableRecognitionNoise(recognized) {
                continue
            }

            guard !cleanExpected.isEmpty else { break }

            let searchStart = max(0, matched - 3)
            let searchEnd = min(cleanExpected.count - 1, matched + 5)
            let candidateRange = searchStart...searchEnd

            if matched < cleanExpected.count && isPotentialPartialMatch(recognized, cleanExpected[matched]) {
                break
            }

            guard let matchedIndex = candidateRange.first(where: {
                isAcceptedMatch(recognized, cleanExpected[$0])
            }) else {
                continue
            }

            if matchedIndex < matched {
                continue
            }

            if matchedIndex > matched {
                for skipped in matched..<matchedIndex {
                    misreadIndices.insert(skipped)
                }
            }

            misreadIndices.remove(matchedIndex)
            matched = matchedIndex + 1
        }
        return matched
    }

    private func normalizedWord(_ word: String) -> String {
        word
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: L.speechLocaleIdentifier))
            .filter { $0.isLetter || $0.isNumber }
    }

    private func isIgnorableRecognitionNoise(_ word: String) -> Bool {
        word.count <= 1
    }

    private func isAcceptedMatch(_ recognized: String, _ expected: String) -> Bool {
        if recognized == expected { return true }
        guard abs(recognized.count - expected.count) <= 1 else { return false }

        switch L.selectedLanguage {
        case .norwegian:
            guard expected.count >= 4 else { return false }
        default:
            guard expected.count >= 5 else { return false }
        }

        return levenshteinDistance(recognized, expected) <= 1
    }

    private func isPotentialPartialMatch(_ recognized: String, _ expected: String) -> Bool {
        guard !recognized.isEmpty, recognized.count < expected.count else { return false }
        return expected.hasPrefix(recognized)
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let aArr = Array(a)
        let bArr = Array(b)

        guard !aArr.isEmpty else { return bArr.count }
        guard !bArr.isEmpty else { return aArr.count }

        var distances = Array(0...bArr.count)

        for (i, charA) in aArr.enumerated() {
            var previousDiagonal = distances[0]
            distances[0] = i + 1

            for (j, charB) in bArr.enumerated() {
                let previous = distances[j + 1]
                if charA == charB {
                    distances[j + 1] = previousDiagonal
                } else {
                    distances[j + 1] = min(
                        distances[j] + 1,
                        distances[j + 1] + 1,
                        previousDiagonal + 1
                    )
                }
                previousDiagonal = previous
            }
        }

        return distances[bArr.count]
    }

    private func updateTranscript(_ text: String) {
        guard text != recognizedText else { return }

        recognizedText = text
        recognizedWords = text
            .components(separatedBy: .whitespacesAndNewlines)
            .map(normalizedWord)
            .filter { !$0.isEmpty }
        lastTranscriptUpdateAt = Date()
        transcriptVersion += 1
    }
}
