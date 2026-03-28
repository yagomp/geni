import SwiftUI

@Observable
@MainActor
class ChapterViewModel {
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
    var dragAnswer: Int? = nil
    var timeRemaining: Int = 60
    var isTimedMode: Bool = false
    var timerTask: Task<Void, Never>? = nil

    init(profile: ChildProfile, chapter: ChapterProgress, exercises: [Exercise], startIndex: Int = 0) {
        self.profile = profile
        self.chapter = chapter
        self.exercises = exercises
        self.currentIndex = startIndex
        self.isTimedMode = chapter.chapterType == .timeAttack

        if isTimedMode {
            startTimer()
        }
    }

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var progress: Double {
        Double(currentIndex) / 20.0
    }

    var isLastExercise: Bool {
        currentIndex >= 19
    }

    func submitAnswer(_ answer: Int, persistence: PersistenceService) {
        guard let exercise = currentExercise else { return }
        attempts += 1

        let actualCorrectAnswer: Int
        switch exercise.format {
        case .solveResult:
            actualCorrectAnswer = exercise.correctAnswer
        case .missingNumber:
            actualCorrectAnswer = exercise.missingNumberCorrectAnswer
        case .trueFalse:
            actualCorrectAnswer = exercise.trueFalseIsCorrect ? 1 : 0
        case .comparison:
            actualCorrectAnswer = exercise.options[0]
        }

        let isCorrect = answer == actualCorrectAnswer

        if exercise.format == .trueFalse || exercise.format == .comparison {
            selectedAnswer = answer
        } else {
            selectedAnswer = answer
        }

        if isCorrect {
            feedbackCorrect = true
            feedbackMessage = attempts == 1 ?
                [L.s(.youGotIt), L.s(.niceJob), L.s(.correct)].randomElement()! :
                L.s(.youGotIt)
            showFeedback = true
            HapticManager.correctAnswer()

            let result = ExerciseResult(
                chapterId: chapter.id,
                exercise: exercise,
                firstCorrect: attempts == 1,
                secondCorrect: attempts == 2 ? true : nil,
                attempts: attempts,
                userAnswer: answer,
                correctAnswer: actualCorrectAnswer
            )
            chapter.exerciseResults.append(result)
            persistence.saveChapterProgress(chapter)

            advanceAfterDelay()
        } else if attempts >= 2 {
            feedbackCorrect = false
            feedbackMessage = "\(actualCorrectAnswer)"
            showAnswer = true
            showFeedback = true
            HapticManager.wrongAnswer()

            let result = ExerciseResult(
                chapterId: chapter.id,
                exercise: exercise,
                firstCorrect: false,
                secondCorrect: false,
                attempts: attempts,
                userAnswer: answer,
                correctAnswer: actualCorrectAnswer
            )
            chapter.exerciseResults.append(result)
            persistence.saveChapterProgress(chapter)

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

    private func advanceAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showFeedback = false
            showAnswer = false
            selectedAnswer = nil
            dragAnswer = nil
            attempts = 0
            currentIndex += 1
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

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    var isTimeUp: Bool {
        isTimedMode && timeRemaining <= 0
    }
}
