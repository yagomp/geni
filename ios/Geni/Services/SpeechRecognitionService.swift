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
        let locale = Locale(identifier: L.isNorwegian ? "nb-NO" : "en-US")
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
        guard let recognizer, recognizer.isAvailable else {
            error = "Speech recognition not available"
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
            self.error = "Audio session error"
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
                if err != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isListening = true
        } catch {
            self.error = "Could not start audio engine"
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

    func matchedWordCount(expected: [String]) -> Int {
        var matched = 0
        let cleanExpected = expected.map { cleanWord($0) }
        for (i, recognized) in recognizedWords.enumerated() {
            guard i < cleanExpected.count else { break }
            if recognized == cleanExpected[i] || levenshteinClose(recognized, cleanExpected[i]) {
                matched = i + 1
            } else {
                break
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
