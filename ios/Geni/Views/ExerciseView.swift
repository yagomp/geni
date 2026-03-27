import SwiftUI

struct ExerciseView: View {
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    let onComplete: (ChapterProgress) -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                exerciseHeader
                    .padding(.horizontal, iPadScale.padding)
                    .padding(.top, iPadScale.padding)

                Spacer()

                if chapterVM.isTimedMode && chapterVM.isTimeUp {
                    timeUpView
                } else if let exercise = chapterVM.currentExercise {
                    exerciseContent(exercise)
                        .padding(.horizontal, iPadScale.padding)
                } else {
                    completingView
                }

                Spacer()

                Color.clear.frame(height: iPadScale.isIPad ? 140 : 100)
            }
            .animation(.spring(response: 0.4), value: chapterVM.currentIndex)

            VStack {
                Spacer()

                if chapterVM.showFeedback {
                    feedbackBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: chapterVM.showFeedback)
        }
        .onChange(of: chapterVM.currentIndex) { _, newValue in
            if newValue >= 20 {
                chapterVM.stopTimer()
                onComplete(chapterVM.chapter)
            }
        }
        .onChange(of: chapterVM.isTimeUp) { _, isUp in
            if isUp {
                onComplete(chapterVM.chapter)
            }
        }
    }

    private var exerciseHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    HapticManager.selection()
                    chapterVM.stopTimer()
                    onExit()
                } label: {
                    Text("◀️").font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(GeniColor.card)
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 3)
                        )
                }

                Spacer()

                if chapterVM.isTimedMode {
                    HStack(spacing: 4) {
                        Text("⏱️")
                        Text("\(chapterVM.timeRemaining)s")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(chapterVM.timeRemaining <= 10 ? GeniColor.pink : GeniColor.border)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(chapterVM.timeRemaining <= 10 ? GeniColor.pink.opacity(0.1) : GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                } else {
                    Text("\(chapterVM.currentIndex + 1) \(L.s(.of20))")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(GeniColor.border)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("⭐")
                    Text("\(chapterVM.chapter.correctCount)")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GeniColor.card)
                .overlay(
                    Rectangle()
                        .stroke(GeniColor.border, lineWidth: 3)
                )
                .background(
                    Rectangle()
                        .fill(GeniColor.border)
                        .offset(x: 3, y: 3)
                )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)

                    Rectangle()
                        .fill(GeniColor.green)
                        .frame(width: geo.size.width * chapterVM.progress, height: 14)
                        .animation(.spring, value: chapterVM.progress)
                }
                .overlay(
                    Rectangle()
                        .stroke(GeniColor.border, lineWidth: 3)
                )
            }
            .frame(height: 14)
        }
    }

    private func exerciseContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            switch exercise.format {
            case .solveResult:
                solveResultContent(exercise)
            case .missingNumber:
                missingNumberContent(exercise)
            case .trueFalse:
                trueFalseContent(exercise)
            case .comparison:
                comparisonContent(exercise)
            }
        }
    }

    private func solveResultContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            HStack(spacing: 8) {
                Text(exercise.prompt)
                    .font(.system(size: iPadScale.value(48), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .contentTransition(.numericText())

                Text("=")
                    .font(.system(size: iPadScale.value(48), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("?")
                    .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(64), height: iPadScale.value(64))
                    .background(GeniColor.card)
                    .overlay(
                        Rectangle()
                            .stroke(GeniColor.border, lineWidth: 3)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            if chapterVM.profile.ageGroup.useDragAndDrop {
                dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            } else {
                tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            }
        }
    }

    private func missingNumberContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            Text(exercise.missingNumberPrompt)
                .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

            if chapterVM.profile.ageGroup.useDragAndDrop {
                dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.missingNumberCorrectAnswer)
            } else {
                tapAnswers(exercise, answers: exercise.options, correctValue: exercise.missingNumberCorrectAnswer)
            }
        }
    }

    private func trueFalseContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            Text(exercise.trueFalsePrompt)
                .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

            HStack(spacing: 16) {
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(1, persistence: persistence)
                } label: {
                    VStack(spacing: 8) {
                        Text("✓")
                            .font(.system(size: 32, weight: .bold))
                        Text(L.s(.trueLabel))
                            .font(.system(.title3, design: .rounded, weight: .black))
                    }
                    .foregroundStyle(trueFalseButtonTextColor(for: 1, exercise: exercise))
                    .frame(maxWidth: .infinity)
                    .frame(height: iPadScale.value(100))
                    .background(trueFalseButtonColor(for: 1, exercise: exercise))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .disabled(chapterVM.showFeedback)

                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(0, persistence: persistence)
                } label: {
                    VStack(spacing: 8) {
                        Text("✗")
                            .font(.system(size: 32, weight: .bold))
                        Text(L.s(.falseLabel))
                            .font(.system(.title3, design: .rounded, weight: .black))
                    }
                    .foregroundStyle(trueFalseButtonTextColor(for: 0, exercise: exercise))
                    .frame(maxWidth: .infinity)
                    .frame(height: iPadScale.value(100))
                    .background(trueFalseButtonColor(for: 0, exercise: exercise))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private func comparisonContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 20) {
            Text(L.s(.whichIsBigger))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.black)

            HStack(spacing: 16) {
                if let left = exercise.comparisonLeft {
                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(0, persistence: persistence)
                    } label: {
                        Text("\(left.0) \(left.1.symbol) \(left.2)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(comparisonTextColor(for: 0, exercise: exercise))
                            .frame(maxWidth: .infinity)
                            .frame(height: iPadScale.value(90))
                            .background(comparisonBgColor(for: 0, exercise: exercise))
                            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                            .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                    }
                    .disabled(chapterVM.showFeedback)
                }

                Text(L.s(.or))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)

                if let right = exercise.comparisonRight {
                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(1, persistence: persistence)
                    } label: {
                        Text("\(right.0) \(right.1.symbol) \(right.2)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(comparisonTextColor(for: 1, exercise: exercise))
                            .frame(maxWidth: .infinity)
                            .frame(height: iPadScale.value(90))
                            .background(comparisonBgColor(for: 1, exercise: exercise))
                            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                            .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                    }
                    .disabled(chapterVM.showFeedback)
                }
            }
        }
        .padding(.vertical, 24)
    }

    private func tapAnswers(_ exercise: Exercise, answers: [Int], correctValue: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ForEach(answers, id: \.self) { option in
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.light)
                    chapterVM.submitAnswer(option, persistence: persistence)
                } label: {
                    Text("\(option)")
                        .font(.system(size: iPadScale.isIPad ? 28 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(answerTextColor(for: option, correct: correctValue))
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale.value(64))
                        .background(answerBgColor(for: option, correct: correctValue))
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 3)
                        )
                        .background(
                            Rectangle()
                                .fill(GeniColor.border)
                                .offset(x: 3, y: 3)
                        )
                }
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private func dragDropAnswers(_ exercise: Exercise, answers: [Int], correctValue: Int) -> some View {
        HStack(spacing: 10) {
            ForEach(answers, id: \.self) { option in
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.dragDrop()
                    chapterVM.dragAnswer = option
                    chapterVM.submitAnswer(option, persistence: persistence)
                } label: {
                    Text("\(option)")
                        .font(.system(size: iPadScale.isIPad ? 28 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(dragTextColor(for: option, correct: correctValue))
                        .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                        .background(dragBubbleColor(for: option, correct: correctValue))
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 3)
                        )
                        .background(
                            Rectangle()
                                .fill(GeniColor.border)
                                .offset(x: 3, y: 3)
                        )
                }
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private var feedbackBanner: some View {
        HStack(spacing: 12) {
            Text(chapterVM.feedbackCorrect ? "✅" : (chapterVM.showAnswer ? "💡" : "🔄"))
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapterVM.feedbackCorrect ? chapterVM.feedbackMessage : (chapterVM.showAnswer ? L.s(.showAnswer) : chapterVM.feedbackMessage))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                if chapterVM.showAnswer {
                    Text("= \(chapterVM.feedbackMessage)")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(chapterVM.feedbackCorrect ? GeniColor.green : (chapterVM.showAnswer ? GeniColor.orange : GeniColor.pink))
        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
        .background(
            Rectangle()
                .fill(GeniColor.border)
                .offset(x: 4, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var completingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L.s(.chapterComplete))
                .font(.system(.title2, design: .rounded, weight: .bold))
        }
    }

    private var timeUpView: some View {
        VStack(spacing: 16) {
            Text("⏱️")
                .font(.system(size: 48))
            Text(L.s(.timeUp))
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
        }
    }

    private func answerBgColor(for option: Int, correct: Int) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return .white
        }
        if option == correct && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return GeniColor.green
        }
        if option == selected && !chapterVM.feedbackCorrect {
            return GeniColor.pink.opacity(0.3)
        }
        return .white
    }

    private func answerTextColor(for option: Int, correct: Int) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return GeniColor.border
        }
        if option == correct && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return .white
        }
        if option == selected && !chapterVM.feedbackCorrect {
            return GeniColor.pink
        }
        return GeniColor.border
    }

    private func dragBubbleColor(for option: Int, correct: Int) -> Color {
        guard chapterVM.showFeedback else {
            return .white
        }
        if option == correct && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return GeniColor.green
        }
        if option == chapterVM.dragAnswer && !chapterVM.feedbackCorrect {
            return GeniColor.pink.opacity(0.3)
        }
        return .white
    }

    private func dragTextColor(for option: Int, correct: Int) -> Color {
        guard chapterVM.showFeedback else {
            return GeniColor.border
        }
        if option == correct && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return .white
        }
        return GeniColor.border
    }

    private func trueFalseButtonColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return GeniColor.card
        }
        let correctValue = exercise.trueFalseIsCorrect ? 1 : 0
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return GeniColor.green
        }
        if value == selected && !chapterVM.feedbackCorrect {
            return GeniColor.pink.opacity(0.3)
        }
        return GeniColor.card
    }

    private func trueFalseButtonTextColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return value == 1 ? GeniColor.green : GeniColor.pink
        }
        let correctValue = exercise.trueFalseIsCorrect ? 1 : 0
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return .white
        }
        if value == selected && !chapterVM.feedbackCorrect {
            return GeniColor.pink
        }
        return value == 1 ? GeniColor.green : GeniColor.pink
    }

    private func comparisonBgColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return .white
        }
        let correctValue = exercise.options[0]
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return GeniColor.green
        }
        if value == selected && !chapterVM.feedbackCorrect {
            return GeniColor.pink.opacity(0.3)
        }
        return .white
    }

    private func comparisonTextColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else {
            return GeniColor.border
        }
        let correctValue = exercise.options[0]
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return .white
        }
        return GeniColor.border
    }
}
