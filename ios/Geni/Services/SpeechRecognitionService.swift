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
        let locale = Locale(identifier: L.speechLocaleIdentifier)
        recognizer = SFSpeechRecognizer(locale: locale)
        isAvailable = recognizer?.isAvailable ?? false

        guard let recognizer, recognizer.isAvailable else {
            error = L.s(.speechRecognitionUnavailable)
            return
        }

        stopListening()

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
                    self.recognizedText = result.bestTranscription.formattedString
                    self.recognizedWords = result.bestTranscription.formattedString
                        .lowercased()
                        .components(separatedBy: " ")
                        .filter { !$0.isEmpty }
                }
                if result?.isFinal == true {
                    // Recognition ended naturally — restart to keep listening
                    self.stopListening()
                    self.startListening()
                } else if err != nil {
                    self.stopListening()
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

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    var misreadIndices: Set<Int> = []

    func matchedWordCount(expected: [String]) -> Int {
        let cleanExpected = expected.map { normalizedWord($0) }
        let cleanRecognized = recognizedWords.map { normalizedWord($0) }.filter { !$0.isEmpty }
        var matched = 0
        var rIdx = 0

        misreadIndices = misreadIndices.filter { $0 < cleanExpected.count }

        for eIdx in 0..<cleanExpected.count {
            guard rIdx < cleanRecognized.count else { break }

            let recognized = cleanRecognized[rIdx]
            let expectedWord = cleanExpected[eIdx]

            if isIgnorableRecognitionNoise(recognized) {
                rIdx += 1
                continue
            }

            if isAcceptedMatch(recognized, expectedWord) {
                misreadIndices.remove(eIdx)
                matched = eIdx + 1
                rIdx += 1
            } else if isPotentialPartialMatch(recognized, expectedWord) {
                break
            } else if rIdx + 1 < cleanRecognized.count,
                      isAcceptedMatch(cleanRecognized[rIdx + 1], expectedWord) {
                // A stray token showed up before the expected word.
                rIdx += 1
                misreadIndices.remove(eIdx)
                matched = eIdx + 1
                rIdx += 1
            } else if eIdx + 1 < cleanExpected.count,
                      isAcceptedMatch(recognized, cleanExpected[eIdx + 1]) {
                // We only mark red when recognition has clearly moved past this word.
                misreadIndices.insert(eIdx)
                matched = eIdx + 1
            } else {
                break
            }
        }
        return matched
    }

    private func normalizedWord(_ word: String) -> String {
        word.lowercased().filter { $0.isLetter || $0.isNumber }
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
}
