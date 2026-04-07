import SwiftUI

@Observable
@MainActor
class ReadingViewModel {
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
        return Double(currentWordIndex) / Double(words.count)
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
                    wordStr.foregroundColor = Color(GeniColor.pink)
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
            recognitionService?.stopListening()
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
        start()
    }

    func stop() {
        isPlaying = false
        isPaused = false
        timerTask?.cancel()
        highlightTask?.cancel()
        speechService?.stop()
        recognitionService?.stopListening()
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

        Task {
            let granted = await recognitionService.requestPermissions()
            guard granted else {
                feedbackMessage = L.s(.micPermissionNeeded)
                showFeedback = true
                return
            }
            recognitionService.startListening()

            highlightTask = Task {
                let expectedWords = words.map { $0.text }
                while !Task.isCancelled && matchedWordCount < words.count {
                    let count = recognitionService.matchedWordCount(expected: expectedWords, startFrom: matchedWordCount)
                    if count > matchedWordCount {
                        matchedWordCount = count
                        HapticManager.impact(.light)
                    }
                    try? await Task.sleep(for: .milliseconds(200))
                }

                guard !Task.isCancelled else { return }
                if matchedWordCount >= words.count {
                    feedbackMessage = L.s(.amazingReading)
                    showFeedback = true
                    HapticManager.notification(.success)
                    try? await Task.sleep(for: .seconds(1.5))
                    guard !Task.isCancelled else { return }
                    completeReading()
                }
            }
        }
    }
}
