import AVFoundation

@Observable
@MainActor
class SpeechService: NSObject {
    var currentWordRange: NSRange?
    var isSpeaking: Bool = false
    var didFinishSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    /// Recorded voice (VoiceLibrary): the playing clip, the clips still to come, and word positions for highlighting.
    private var player: AVAudioPlayer?
    private var queuedClips: [VoiceLibrary.Clip] = []
    private var wordTimings: [(start: TimeInterval, range: NSRange)] = []
    private var wordTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, rate: Float = 0.42) {
        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
        } catch {
            // Continue anyway — speech may still work
        }

        didFinishSpeaking = false
        isSpeaking = true
        if let clips = VoiceLibrary.clips(for: text, language: L.speechLocaleIdentifier) {
            let words = ReadingContentService.parseWords(from: text)
            if clips.count == 1, clips[0].wordStartsMs.count == words.count {
                wordTimings = zip(clips[0].wordStartsMs, words).map {
                    (Double($0) / 1000, NSRange(location: $1.startIndex, length: $1.endIndex - $1.startIndex))
                }
            }
            queuedClips = clips
            if playNextClip() { return }
            clearClips()
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: L.speechLocaleIdentifier)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.1
        utterance.preUtteranceDelay = 0.3
        synthesizer.speak(utterance)
    }

    func pause() {
        if let player {
            player.pause()
            wordTask?.cancel()
            isSpeaking = false
        } else {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    func resume() {
        if let player {
            player.play()
            isSpeaking = true
            trackWords()
        } else {
            synthesizer.continueSpeaking()
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        clearClips()
        isSpeaking = false
        currentWordRange = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func speechRate(for ageGroup: AgeGroup) -> Float {
        switch ageGroup {
        case .young: return 0.35
        case .middle: return 0.42
        case .older: return 0.48
        }
    }

    /// Starts the next queued clip; false when there is none or it can't be opened.
    private func playNextClip() -> Bool {
        guard !queuedClips.isEmpty, let next = try? AVAudioPlayer(contentsOf: queuedClips.removeFirst().url) else {
            return false
        }
        next.delegate = self
        player = next
        guard next.play() else { return false }
        if !wordTimings.isEmpty { trackWords() }
        return true
    }

    private func clearClips() {
        player?.stop()
        player = nil
        queuedClips = []
        wordTimings = []
        wordTask?.cancel()
    }

    private func trackWords() {
        wordTask?.cancel()
        guard player != nil, !wordTimings.isEmpty else { return }
        wordTask = Task { [weak self] in
            while !Task.isCancelled, let self, let now = self.player?.currentTime {
                if let word = self.wordTimings.last(where: { $0.start <= now }), self.currentWordRange != word.range {
                    self.currentWordRange = word.range
                }
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
    }

    private func clipFinished(_ finished: AVAudioPlayer) {
        guard finished === player else { return }
        if playNextClip() { return }
        wordTask?.cancel()
        player = nil
        isSpeaking = false
        didFinishSpeaking = true
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.player, ObjectIdentifier(current) == id else { return }
            self.clipFinished(current)
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentWordRange = characterRange
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.didFinishSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
}
