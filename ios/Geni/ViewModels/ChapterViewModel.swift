import SwiftUI

struct MatchStroke: Equatable {
    let leftIndex: Int
    let rightIndex: Int
    let id = UUID()
}

@Observable
@MainActor
class ChapterViewModel {
    /// Immediate feedback supports simulations without sleeping or playing device effects.
    enum Feedback { case animated, immediate }
    private let feedback: Feedback

    let profile: ChildProfile
    var chapter: ChapterProgress
    let exercises: [Exercise]
    var currentIndex: Int
    var attempts: Int = 0
    var showFeedback: Bool = false
    var feedbackCorrect: Bool = false
    var feedbackMessage: String = ""
    var showAnswer: Bool = false
    var selectedAnswer: Int? = nil
    var completedChapter: ChapterProgress? = nil
    var xpEarned: Int = 0
    /// Both-done bonus paid with this chapter (reading came first today); 0 otherwise.
    var bonusCoins: Int = 0
    var dragAnswer: Int? = nil
    var completedMatches: [MatchStroke] = []
    var wrongMatchStroke: MatchStroke? = nil
    var evenOddStep: Int = 0
    var timeRemaining: Int = 60
    var isTimedMode: Bool = false
    var timerTask: Task<Void, Never>? = nil
    var isAwaitingAdvance: Bool = false
    private(set) var wrongMatchCount: Int = 0
    private(set) var hasCompleted: Bool = false

    init(profile: ChildProfile, chapter: ChapterProgress, exercises: [Exercise], startIndex: Int = 0, feedback: Feedback = .animated) {
        // The chapter is as long as what was generated for it (10 for ages 4–5, else 20)
        var chapter = chapter
        if !exercises.isEmpty { chapter.exerciseCount = exercises.count }
        self.feedback = feedback
        self.profile = profile
        self.chapter = chapter
        self.exercises = exercises
        self.currentIndex = min(startIndex, exercises.count)
        self.isTimedMode = chapter.chapterType == .timeAttack

        if isTimedMode {
            startTimer()
        }
    }

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var totalExercises: Int {
        max(exercises.count, 1)
    }

    var progress: Double {
        Double(min(currentIndex, totalExercises)) / Double(totalExercises)
    }

    var isLastExercise: Bool {
        currentIndex >= totalExercises - 1
    }

    func submitAnswer(_ answer: Int, persistence: PersistenceService) {
        guard let exercise = currentExercise else { return }
        guard !isAwaitingAdvance else { return }
        attempts += 1

        let actualCorrectAnswer: Int
        switch exercise.format {
        case .solveResult, .countingObjects, .visualAddition, .tenFrame,
             .numberBonds, .diceAddition, .visualSubtraction,
             .multiStep, .numberSequence, .areaPerimeter, .fractionPick, .longDivision, .clockRead, .clockSet, .game:
            actualCorrectAnswer = exercise.correctAnswer
        case .missingNumber:
            actualCorrectAnswer = exercise.missingNumberCorrectAnswer
        case .trueFalse:
            actualCorrectAnswer = exercise.trueFalseIsCorrect ? 1 : 0
        case .comparison, .compareGroups:
            actualCorrectAnswer = exercise.options[0]
        case .evenOddSort:
            if evenOddStep == 0 {
                actualCorrectAnswer = exercise.correctAnswer
            } else {
                actualCorrectAnswer = exercise.correctAnswer % 2 == 0 ? 0 : 1
            }
        case .matchConnect, .clockMatch:
            actualCorrectAnswer = answer
        }

        let isCorrect = answer == actualCorrectAnswer

        if exercise.format == .trueFalse || exercise.format == .comparison {
            selectedAnswer = answer
        } else {
            selectedAnswer = answer
        }

        if isCorrect {
            // EvenOddSort step 0 → advance to classification step
            if exercise.format == .evenOddSort && evenOddStep == 0 {
                feedbackCorrect = true
                feedbackMessage = L.s(.correct)
                showFeedback = true
                playCorrectAnswerFeedback()
                afterFeedbackDelay(.seconds(1.0)) { [self] in
                    showFeedback = false
                    selectedAnswer = nil
                    dragAnswer = nil
                    attempts = 0
                    evenOddStep = 1
                }
                return
            }

            feedbackCorrect = true
            feedbackMessage = attempts == 1 ?
                [L.s(.youGotIt), L.s(.niceJob), L.s(.correct)].randomElement()! :
                L.s(.youGotIt)
            showFeedback = true
            playCorrectAnswerFeedback()

            let result = ExerciseResult(
                chapterId: chapter.id,
                exercise: exercise,
                firstCorrect: attempts == 1,
                secondCorrect: attempts == 2 ? true : nil,
                attempts: attempts
            )
            recordCompletedExercise(result, persistence: persistence)

            advanceAfterDelay()
        } else if attempts >= 2 {
            feedbackCorrect = false
            feedbackMessage = exercise.game?.answerText
                ?? (exercise.format.isClock ? ClockTime(totalMinutes: actualCorrectAnswer).digital : "\(actualCorrectAnswer)")
            showAnswer = true
            showFeedback = true
            HapticManager.wrongAnswer()

            let result = ExerciseResult(
                chapterId: chapter.id,
                exercise: exercise,
                firstCorrect: false,
                secondCorrect: false,
                attempts: attempts
            )
            recordCompletedExercise(result, persistence: persistence)

            advanceAfterDelay()
        } else {
            feedbackCorrect = false
            feedbackMessage = [L.s(.tryAgain), L.s(.almostThere)].randomElement()!
            showFeedback = true
            HapticManager.wrongAnswer()

            Task {
                try? await Task.sleep(for: .seconds(1.0))
                showFeedback = false
                selectedAnswer = nil
            }
        }
    }

    func submitClockTime(_ time: ClockTime, persistence: PersistenceService) {
        guard let exercise = currentExercise, exercise.format == .clockSet, !showFeedback else { return }
        submitAnswer(time.snapped(to: exercise.clockMinuteStep).totalMinutes, persistence: persistence)
    }

    func submitMatch(leftIndex: Int, rightIndex: Int, persistence: PersistenceService) {
        guard let exercise = currentExercise,
              let correctIndices = exercise.correctMatchIndices else { return }
        guard !isAwaitingAdvance,
              correctIndices.indices.contains(leftIndex),
              !completedMatches.contains(where: { $0.leftIndex == leftIndex || $0.rightIndex == rightIndex })
        else { return }

        let stroke = MatchStroke(leftIndex: leftIndex, rightIndex: rightIndex)

        if correctIndices[leftIndex] == rightIndex {
            completedMatches.append(stroke)
            playCorrectAnswerFeedback()

            if completedMatches.count == correctIndices.count {
                feedbackCorrect = true
                feedbackMessage = [L.s(.youGotIt), L.s(.niceJob), L.s(.correct)].randomElement()!
                showFeedback = true

                let result = ExerciseResult(
                    chapterId: chapter.id,
                    exercise: exercise,
                    firstCorrect: wrongMatchCount == 0,
                    secondCorrect: wrongMatchCount == 1 ? true : nil,
                    attempts: wrongMatchCount + 1
                )
                recordCompletedExercise(result, persistence: persistence)
                advanceAfterDelay()
            }
        } else {
            wrongMatchCount += 1
            wrongMatchStroke = stroke
            HapticManager.wrongAnswer()
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                if wrongMatchStroke == stroke {
                    wrongMatchStroke = nil
                }
            }
        }
    }

    private func recordCompletedExercise(_ result: ExerciseResult, persistence: PersistenceService) {
        chapter.exerciseResults.append(result)
        chapter.completedExerciseCount = max(chapter.completedExerciseCount, currentIndex + 1)
        persistence.saveChapterProgress(chapter)
    }

    private func advanceAfterDelay() {
        isAwaitingAdvance = true
        afterFeedbackDelay(.seconds(1.5)) { [self] in
            guard !hasCompleted else { return }
            showFeedback = false
            showAnswer = false
            selectedAnswer = nil
            dragAnswer = nil
            attempts = 0
            evenOddStep = 0
            completedMatches = []
            wrongMatchCount = 0
            wrongMatchStroke = nil
            currentIndex += 1
            isAwaitingAdvance = false
        }
    }

    private func playCorrectAnswerFeedback() {
        guard feedback == .animated else { return }
        if let kind = currentExercise?.game?.kind, kind == .codingPath || kind == .codingLoop {
            HapticManager.robotArrive()
        } else {
            HapticManager.correctAnswer()
        }
    }

    private func afterFeedbackDelay(_ delay: Duration, action: @escaping @MainActor () -> Void) {
        if feedback == .immediate {
            action()
        } else {
            Task {
                try? await Task.sleep(for: delay)
                action()
            }
        }
    }

    private func startTimer() {
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    timeRemaining -= 1
                }
            }
        }
    }

    /// Returns true exactly once; the timer and the final answer can both end a chapter.
    func claimCompletion() -> Bool {
        guard !hasCompleted else { return false }
        hasCompleted = true
        stopTimer()
        return true
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    var isTimeUp: Bool {
        isTimedMode && timeRemaining <= 0
    }
}
