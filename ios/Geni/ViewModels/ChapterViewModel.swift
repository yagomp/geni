import SwiftUI

struct MatchStroke: Equatable {
    let leftIndex: Int
    let rightIndex: Int
    let points: [CGPoint]
}

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
    var completedMatches: [MatchStroke] = []
    var activeDragSource: Int? = nil
    var activeDragPoints: [CGPoint] = []
    var wrongMatchStroke: MatchStroke? = nil
    var evenOddStep: Int = 0
    var timeRemaining: Int = 60
    var isTimedMode: Bool = false
    var timerTask: Task<Void, Never>? = nil
    var isAwaitingAdvance: Bool = false

    init(profile: ChildProfile, chapter: ChapterProgress, exercises: [Exercise], startIndex: Int = 0) {
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
             .multiStep, .numberSequence, .areaPerimeter, .fractionPick, .longDivision:
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
        case .matchConnect:
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
                HapticManager.correctAnswer()
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
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
            HapticManager.correctAnswer()

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
            feedbackMessage = "\(actualCorrectAnswer)"
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

    func beginMatchDrag(from leftIndex: Int, startPoint: CGPoint) {
        guard !isAwaitingAdvance else { return }
        activeDragSource = leftIndex
        activeDragPoints = [startPoint]
    }

    func updateMatchDrag(to point: CGPoint) {
        guard activeDragSource != nil else { return }

        if let lastPoint = activeDragPoints.last {
            let distance = hypot(point.x - lastPoint.x, point.y - lastPoint.y)
            if distance < 4 {
                activeDragPoints[activeDragPoints.count - 1] = point
                return
            }
        }

        activeDragPoints.append(point)
    }

    func endMatchDrag(
        from leftIndex: Int,
        finalPoint: CGPoint,
        rightIndex: Int?,
        snappedTargetPoint: CGPoint?,
        persistence: PersistenceService
    ) {
        guard activeDragSource == leftIndex else { return }

        updateMatchDrag(to: finalPoint)
        let pathPoints = normalizedMatchPath(snappedTargetPoint: snappedTargetPoint)
        resetActiveMatchDrag()

        guard let rightIndex else { return }
        submitMatch(leftIndex: leftIndex, rightIndex: rightIndex, pathPoints: pathPoints, persistence: persistence)
    }

    func submitMatch(leftIndex: Int, rightIndex: Int, pathPoints: [CGPoint], persistence: PersistenceService) {
        guard let exercise = currentExercise,
              let correctIndices = exercise.correctMatchIndices else { return }
        guard !isAwaitingAdvance else { return }

        let stroke = MatchStroke(leftIndex: leftIndex, rightIndex: rightIndex, points: pathPoints)

        if correctIndices[leftIndex] == rightIndex {
            completedMatches.append(stroke)
            HapticManager.correctAnswer()

            if completedMatches.count == correctIndices.count {
                feedbackCorrect = true
                feedbackMessage = [L.s(.youGotIt), L.s(.niceJob), L.s(.correct)].randomElement()!
                showFeedback = true

                let result = ExerciseResult(
                    chapterId: chapter.id,
                    exercise: exercise,
                    firstCorrect: true,
                    secondCorrect: nil,
                    attempts: 1
                )
                recordCompletedExercise(result, persistence: persistence)
                advanceAfterDelay()
            }
        } else {
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
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showFeedback = false
            showAnswer = false
            selectedAnswer = nil
            dragAnswer = nil
            attempts = 0
            evenOddStep = 0
            completedMatches = []
            resetActiveMatchDrag()
            wrongMatchStroke = nil
            currentIndex += 1
            isAwaitingAdvance = false
        }
    }

    private func normalizedMatchPath(snappedTargetPoint: CGPoint?) -> [CGPoint] {
        var points = activeDragPoints
        if let snappedTargetPoint {
            if let lastPoint = points.last, hypot(lastPoint.x - snappedTargetPoint.x, lastPoint.y - snappedTargetPoint.y) < 2 {
                points[points.count - 1] = snappedTargetPoint
            } else {
                points.append(snappedTargetPoint)
            }
        }
        return points
    }

    private func resetActiveMatchDrag() {
        activeDragSource = nil
        activeDragPoints = []
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
