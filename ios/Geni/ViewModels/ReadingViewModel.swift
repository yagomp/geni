import SwiftUI

@Observable
@MainActor
class ReadingViewModel {
    enum FeedbackTone {
        case success
        case guidance
        case error
    }

    let profile: ChildProfile
    let readingText: ReadingText
    var mode: ReadingMode
    var words: [ReadingWord]
    var currentWordIndex: Int = 0
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var elapsedSeconds: Int = 0
    var targetSeconds: Int
    var isCompleted: Bool = false
    var coinsEarned: Int = 0
    var session: ReadingSession

    var speechService: SpeechService?
    var recognitionService: SpeechRecognitionService?
    var matchedWordCount: Int = 0
    var feedbackMessage: String = ""
    var showFeedback: Bool = false
    var feedbackTone: FeedbackTone = .success

    private var timerTask: Task<Void, Never>?
    private var highlightTask: Task<Void, Never>?

    init(profile: ChildProfile, readingText: ReadingText, mode: ReadingMode, date: String) {
        self.profile = profile
        self.readingText = readingText
        self.mode = mode
        self.words = ReadingContentService.parseWords(from: readingText.content)
        let target = ReadingText.targetReadingSeconds(for: profile.age)
        self.targetSeconds = target
        self.session = ReadingSession(
            childId: profile.id,
            date: date,
            readingTextId: readingText.id,
            mode: mode,
            targetTimeSeconds: target
        )

        if mode == .readToMe {
            speechService = SpeechService()
        } else if mode == .listenToMeRead {
            recognitionService = SpeechRecognitionService()
        }
    }

    var progress: Double {
        guard !words.isEmpty else { return 0 }
        let completedWords = mode == .listenToMeRead ? matchedWordCount : currentWordIndex
        return Double(min(completedWords, words.count)) / Double(words.count)
    }

    var timeProgress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(targetSeconds))
    }

    var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedTarget: String {
        let m = targetSeconds / 60
        let s = targetSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var attributedContent: AttributedString {
        var result = AttributedString()
        for (i, word) in words.enumerated() {
            let separator = i < words.count - 1 ? " " : ""
            var wordStr = AttributedString(word.text + separator)

            if mode == .listenToMeRead {
                let isMisread = recognitionService?.misreadIndices.contains(i) == true
                if i < matchedWordCount && isMisread {
                    wordStr.foregroundColor = Color(GeniColor.orange)
                    wordStr.underlineStyle = .single
                } else if i < matchedWordCount {
                    wordStr.foregroundColor = Color(GeniColor.green)
                } else if i == matchedWordCount {
                    wordStr.foregroundColor = Color(GeniColor.border)
                    wordStr.underlineStyle = .single
                } else {
                    wordStr.foregroundColor = Color.gray.opacity(0.35)
                }
            } else {
                if i < currentWordIndex {
                    wordStr.foregroundColor = Color(GeniColor.border)
                } else if i == currentWordIndex && isPlaying {
                    wordStr.foregroundColor = Color(GeniColor.blue)
                } else {
                    wordStr.foregroundColor = Color.gray.opacity(0.35)
                }
            }
            result += wordStr
        }
        return result
    }

    func start() {
        isPlaying = true
        isPaused = false
        startTimer()

        switch mode {
        case .readByMyself:
            startSelfPacedHighlighting()
        case .readToMe:
            startReadToMe()
        case .listenToMeRead:
            startListenMode()
        }
    }

    func pause() {
        isPaused = true
        isPlaying = false
        timerTask?.cancel()
        highlightTask?.cancel()

        if mode == .readToMe {
            speechService?.pause()
        } else if mode == .listenToMeRead {
            recognitionService?.stopListening(clearTranscript: false)
        }
    }

    func resume() {
        isPaused = false
        isPlaying = true
        startTimer()

        switch mode {
        case .readByMyself:
            startSelfPacedHighlighting()
        case .readToMe:
            speechService?.resume()
        case .listenToMeRead:
            recognitionService?.startListening()
        }
    }

    func restart() {
        stop()
        currentWordIndex = 0
        elapsedSeconds = 0
        matchedWordCount = 0
        isCompleted = false
        feedbackMessage = ""
        showFeedback = false
        feedbackTone = .success
        recognitionService?.resetTranscript(clearMisreads: true)
        start()
    }

    func stop() {
        isPlaying = false
        isPaused = false
        timerTask?.cancel()
        highlightTask?.cancel()
        speechService?.stop()
        recognitionService?.stopListening(clearTranscript: true)
    }

    func completeReading() {
        stop()
        isCompleted = true
        session.readingTimeSeconds = elapsedSeconds
        session.complete()
        coinsEarned = session.coinsEarned
        HapticManager.coinReward()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                elapsedSeconds += 1
            }
        }
    }

    private func startSelfPacedHighlighting() {
        highlightTask?.cancel()
        let baseInterval = ReadingContentService.secondsPerWord(
            totalWords: words.count,
            targetSeconds: targetSeconds
        )

        highlightTask = Task {
            while currentWordIndex < words.count && !Task.isCancelled {
                let word = words[currentWordIndex]
                let pauseTime = word.pauseDuration
                let interval = baseInterval + pauseTime

                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                currentWordIndex += 1
            }

            guard !Task.isCancelled else { return }
            if currentWordIndex >= words.count {
                completeReading()
            }
        }
    }

    private func startReadToMe() {
        guard let speechService else { return }
        let rate = speechService.speechRate(for: profile.ageGroup)
        speechService.speak(readingText.content, rate: rate)

        highlightTask = Task {
            while !Task.isCancelled && !speechService.didFinishSpeaking {
                if let range = speechService.currentWordRange {
                    let charPos = range.location
                    for (i, word) in words.enumerated() {
                        if word.startIndex <= charPos && charPos < word.endIndex + 1 {
                            if currentWordIndex != i {
                                currentWordIndex = i
                            }
                            break
                        }
                    }
                }
                try? await Task.sleep(for: .milliseconds(50))
            }

            guard !Task.isCancelled else { return }
            currentWordIndex = words.count
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            completeReading()
        }
    }

    private func startListenMode() {
        guard let recognitionService else { return }
        recognitionService.resetTranscript(clearMisreads: false)
        currentWordIndex = matchedWordCount

        Task {
            let granted = await recognitionService.requestPermissions()
            guard granted else {
                feedbackMessage = L.s(.micPermissionNeeded)
                feedbackTone = .error
                showFeedback = true
                return
            }
            recognitionService.startListening()

            highlightTask = Task {
                let expectedWords = words.map { $0.text }
                var lastProgressAt = Date()
                var lastFeedbackAt = Date.distantPast
                var lastTranscriptVersion = recognitionService.transcriptVersion
                var lastTranscriptUpdateAt = recognitionService.lastTranscriptUpdateAt ?? Date()

                while !Task.isCancelled && matchedWordCount < words.count {
                    let count = recognitionService.matchedWordCount(expected: expectedWords, startFrom: matchedWordCount)
                    if count > matchedWordCount {
                        matchedWordCount = count
                        currentWordIndex = count
                        lastProgressAt = Date()
                        lastTranscriptVersion = recognitionService.transcriptVersion
                        lastTranscriptUpdateAt = recognitionService.lastTranscriptUpdateAt ?? lastProgressAt
                        if feedbackTone != .error {
                            showFeedback = false
                            feedbackMessage = ""
                        }
                        HapticManager.impact(.light)
                    }

                    if recognitionService.transcriptVersion != lastTranscriptVersion {
                        lastTranscriptVersion = recognitionService.transcriptVersion
                        lastTranscriptUpdateAt = recognitionService.lastTranscriptUpdateAt ?? Date()
                    }

                    let now = Date()
                    let stalledFor = now.timeIntervalSince(lastProgressAt)
                    let transcriptQuietFor = now.timeIntervalSince(lastTranscriptUpdateAt)

                    if let error = recognitionService.error, !error.isEmpty {
                        feedbackMessage = error
                        feedbackTone = .error
                        showFeedback = true
                    } else if stalledFor >= listenWarningSeconds,
                              transcriptQuietFor >= 1.0,
                              now.timeIntervalSince(lastFeedbackAt) >= 2.0 {
                        feedbackMessage = L.s(.letsKeepGoing)
                        feedbackTone = .guidance
                        showFeedback = true
                        lastFeedbackAt = now
                    }

                    if stalledFor >= listenAutoAdvanceSeconds && transcriptQuietFor >= 1.5 {
                        skipCurrentListenWord()
                        lastProgressAt = now
                        lastFeedbackAt = now
                        lastTranscriptUpdateAt = now
                        recognitionService.resetTranscript(clearMisreads: false)
                        if !recognitionService.isListening {
                            recognitionService.startListening()
                        }
                    }

                    try? await Task.sleep(for: .milliseconds(150))
                }

                guard !Task.isCancelled else { return }
                if matchedWordCount >= words.count {
                    feedbackMessage = L.s(.amazingReading)
                    feedbackTone = .success
                    showFeedback = true
                    HapticManager.notification(.success)
                    try? await Task.sleep(for: .seconds(1.5))
                    guard !Task.isCancelled else { return }
                    completeReading()
                }
            }
        }
    }

    func skipCurrentListenWord() {
        guard mode == .listenToMeRead, matchedWordCount < words.count else { return }

        recognitionService?.misreadIndices.insert(matchedWordCount)
        matchedWordCount += 1
        currentWordIndex = matchedWordCount
        feedbackMessage = L.s(.letsKeepGoing)
        feedbackTone = .guidance
        showFeedback = true
        HapticManager.impact(.light)
    }

    private var listenWarningSeconds: TimeInterval {
        switch profile.ageGroup {
        case .young: return 2.5
        case .middle: return 3.0
        case .older: return 3.5
        }
    }

    private var listenAutoAdvanceSeconds: TimeInterval {
        listenWarningSeconds + 2.0
    }
}
