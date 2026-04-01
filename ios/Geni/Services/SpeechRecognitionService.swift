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
        let cleanExpected = expected.map { cleanWord($0) }
        let cleanRecognized = recognizedWords.map { cleanWord($0) }
        var matched = 0
        var rIdx = 0

        for eIdx in 0..<cleanExpected.count {
            guard rIdx < cleanRecognized.count else { break }

            if cleanRecognized[rIdx] == cleanExpected[eIdx] || levenshteinClose(cleanRecognized[rIdx], cleanExpected[eIdx]) {
                misreadIndices.remove(eIdx)
                matched = eIdx + 1
                rIdx += 1
            } else {
                // Check if the user skipped this word and said the next one
                if rIdx + 1 < cleanRecognized.count && eIdx + 1 < cleanExpected.count &&
                   (cleanRecognized[rIdx + 1] == cleanExpected[eIdx] || levenshteinClose(cleanRecognized[rIdx + 1], cleanExpected[eIdx])) {
                    // The extra recognized word was a misread — skip it
                    rIdx += 1
                    misreadIndices.remove(eIdx)
                    matched = eIdx + 1
                    rIdx += 1
                } else if rIdx < cleanRecognized.count &&
                          eIdx + 1 < cleanExpected.count &&
                          (cleanRecognized[rIdx] == cleanExpected[eIdx + 1] || levenshteinClose(cleanRecognized[rIdx], cleanExpected[eIdx + 1])) {
                    // User skipped a word — mark it misread and continue
                    misreadIndices.insert(eIdx)
                    matched = eIdx + 1
                    // Don't advance rIdx — it matches the next expected word
                } else {
                    // Genuine mismatch at current position — mark misread but keep going
                    misreadIndices.insert(eIdx)
                    matched = eIdx + 1
                    rIdx += 1
                }
            }
        }
        return matched
    }

    private func cleanWord(_ word: String) -> String {
        word.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func levenshteinClose(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        if abs(a.count - b.count) > 2 { return false }
        let shorter = min(a.count, b.count)
        guard shorter > 0 else { return false }
        var common = 0
        let aArr = Array(a)
        let bArr = Array(b)
        for i in 0..<min(aArr.count, bArr.count) {
            if aArr[i] == bArr[i] { common += 1 }
        }
        return Double(common) / Double(max(a.count, b.count)) >= 0.6
    }
}
