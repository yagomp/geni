import SwiftUI

struct DiceFaceView: View {
    let value: Int
    @Environment(\.geniExpandedLayout) private var expanded
    private var size: CGFloat { expanded ? 136 : iPadScale.value(72) }
    private var dotSize: CGFloat { expanded ? 26 : iPadScale.value(14) }

    var body: some View {
        ZStack {
            GeniShape()
                .fill(GeniColor.card)
                .frame(width: size, height: size)
                .overlay(GeniShape().stroke(GeniColor.hairline, lineWidth: 1))
                .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)

            Canvas { context, canvasSize in
                let inset: CGFloat = canvasSize.width * 0.22
                let mid = canvasSize.width / 2
                let left = inset
                let right = canvasSize.width - inset
                let top = inset
                let bottom = canvasSize.height - inset

                let positions: [CGPoint]
                switch value {
                case 1: positions = [CGPoint(x: mid, y: mid)]
                case 2: positions = [CGPoint(x: left, y: top), CGPoint(x: right, y: bottom)]
                case 3: positions = [CGPoint(x: left, y: top), CGPoint(x: mid, y: mid), CGPoint(x: right, y: bottom)]
                case 4: positions = [CGPoint(x: left, y: top), CGPoint(x: right, y: top), CGPoint(x: left, y: bottom), CGPoint(x: right, y: bottom)]
                case 5: positions = [CGPoint(x: left, y: top), CGPoint(x: right, y: top), CGPoint(x: mid, y: mid), CGPoint(x: left, y: bottom), CGPoint(x: right, y: bottom)]
                case 6: positions = [CGPoint(x: left, y: top), CGPoint(x: right, y: top), CGPoint(x: left, y: mid), CGPoint(x: right, y: mid), CGPoint(x: left, y: bottom), CGPoint(x: right, y: bottom)]
                default: positions = []
                }

                let r = dotSize / 2
                for pos in positions {
                    let rect = CGRect(x: pos.x - r, y: pos.y - r, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.black))
                }
            }
            .frame(width: size, height: size)
        }
    }
}

struct ExerciseView: View {
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    let onComplete: (ChapterProgress) -> Void
    let onExit: () -> Void

    var body: some View {
        GeniLearningLayout {
            ExerciseViewLayout(chapterVM: chapterVM, persistence: persistence, onComplete: onComplete, onExit: onExit)
        }
    }
}

private struct ExerciseViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    let onComplete: (ChapterProgress) -> Void
    let onExit: () -> Void
    @State private var speech = SpeechService()

    private func scaled(_ value: CGFloat) -> CGFloat {
        expanded ? value * 1.9 : iPadScale.value(value)
    }

    /// Ages 4–5 can't read the question yet, so it's spoken when it appears and on 🔊.
    private var readsQuestionsAloud: Bool { chapterVM.profile.age <= 5 }

    private func speakQuestion() {
        guard readsQuestionsAloud, !chapterVM.showFeedback,
              let text = chapterVM.currentExercise?.spokenPrompt else { return }
        speech.speak(text, rate: speech.speechRate(for: chapterVM.profile.ageGroup))
    }

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            if expanded {
                VStack(spacing: 0) {
                    exerciseHeader
                        .padding(.horizontal, 40)
                        .padding(.top, 28)

                    GeometryReader { remaining in
                        ScrollView {
                            currentContent
                                .environment(\.geniExerciseViewport,
                                             CGSize(width: remaining.size.width - 80, height: remaining.size.height - 172))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 36)
                                .frame(minHeight: max(0, remaining.size.height - 100))
                                .padding(.bottom, 100)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    exerciseHeader
                        .padding(.horizontal, iPadScale.padding)
                        .padding(.top, iPadScale.padding)

                    GeometryReader { remaining in
                        ScrollView {
                            currentContent
                                .environment(\.geniExerciseViewport,
                                             CGSize(width: remaining.size.width - iPadScale.padding * 2, height: remaining.size.height - 32))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, iPadScale.padding)
                                .padding(.vertical, 16)
                                .frame(minHeight: remaining.size.height)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .id(chapterVM.currentIndex)
                    }

                    Color.clear.frame(height: iPadScale.isIPad ? 140 : 100)
                }
            }

            VStack {
                Spacer()

                if chapterVM.showFeedback {
                    feedbackBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: chapterVM.showFeedback)
        }
        .animation(.spring(response: 0.4), value: chapterVM.currentIndex)
        .onChange(of: chapterVM.currentIndex) { _, newValue in
            if newValue >= chapterVM.totalExercises, chapterVM.claimCompletion() {
                onComplete(chapterVM.chapter)
            } else {
                speakQuestion()
            }
        }
        .onChange(of: chapterVM.showFeedback) { _, showing in
            if showing && (readsQuestionsAloud || speech.isSpeaking) { speech.stop() }
        }
        .onAppear { speakQuestion() }
        .onDisappear { speech.stop() }
        .onChange(of: chapterVM.isTimeUp) { _, isUp in
            if isUp, chapterVM.claimCompletion() {
                onComplete(chapterVM.chapter)
            }
        }
    }

    @ViewBuilder
    private var currentContent: some View {
        if chapterVM.isTimedMode && chapterVM.isTimeUp {
            timeUpView
        } else if let exercise = chapterVM.currentExercise {
            exerciseContent(exercise).compositingGroup()
        } else {
            completingView
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
                    Text("◀️").font(.system(size: expanded ? 28 : 20))
                        .frame(width: expanded ? 64 : 44, height: expanded ? 64 : 44)
                        .softSurface(GeniColor.card)
                }
                .accessibilityIdentifier("exercise.back")

                if readsQuestionsAloud {
                    Button {
                        HapticManager.selection()
                        speakQuestion()
                    } label: {
                        Text("🔊").font(.system(size: expanded ? 28 : 20))
                            .frame(width: expanded ? 64 : 44, height: expanded ? 64 : 44)
                            .softSurface(GeniColor.card)
                    }
                    .accessibilityLabel(L.s(.readQuestionAloud))
                    .accessibilityIdentifier("exercise.readAloud")
                }

                Spacer()

                if chapterVM.isTimedMode {
                    HStack(spacing: 4) {
                        Text("⏱️")
                        Text("\(chapterVM.timeRemaining)s")
                            .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                            .foregroundStyle(chapterVM.timeRemaining <= 10 ? GeniColor.pinkDeep : GeniColor.border)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .softSurface(chapterVM.timeRemaining <= 10 ? GeniColor.pink.soft(0.15) : GeniColor.card)
                } else {
                    Text("\(chapterVM.currentIndex + 1) \(String(format: L.s(.of20), chapterVM.totalExercises))")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .bold))
                        .foregroundStyle(GeniColor.border)
                        .accessibilityIdentifier("exercise.counter")
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("⭐")
                    Text("\(chapterVM.chapter.correctCount)")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .softSurface(GeniColor.card)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    GeniShape()
                        .fill(GeniColor.lightGray.soft(0.6))
                        .frame(height: expanded ? 20 : 14)

                    Rectangle()
                        .fill(GeniColor.green)
                        .frame(width: geo.size.width * chapterVM.progress, height: expanded ? 20 : 14)
                        .animation(.spring, value: chapterVM.progress)
                }
                .clipShape(GeniShape())
            }
            .frame(height: expanded ? 20 : 14)
        }
    }

    private func exerciseContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            switch exercise.format {
            case .solveResult:
                solveResultContent(exercise)
            case .missingNumber:
                missingNumberContent(exercise)
            case .trueFalse:
                trueFalseContent(exercise)
            case .comparison:
                comparisonContent(exercise)
            case .countingObjects:
                countingObjectsContent(exercise)
            case .visualAddition:
                visualAdditionContent(exercise)
            case .compareGroups:
                compareGroupsContent(exercise)
            case .tenFrame:
                tenFrameContent(exercise)
            case .matchConnect:
                matchConnectContent(exercise)
            case .numberBonds:
                numberBondsContent(exercise)
            case .diceAddition:
                diceAdditionContent(exercise)
            case .evenOddSort:
                evenOddSortContent(exercise)
            case .visualSubtraction:
                visualSubtractionContent(exercise)
            case .multiStep:
                multiStepContent(exercise)
            case .numberSequence:
                numberSequenceContent(exercise)
            case .areaPerimeter:
                areaPerimeterContent(exercise)
            case .fractionPick:
                fractionPickContent(exercise)
            case .longDivision:
                longDivisionContent(exercise)
            case .clockRead, .clockSet, .clockMatch:
                ClockExerciseView(exercise: exercise, chapterVM: chapterVM, persistence: persistence)
                    .id(exercise.id)
            case .game:
                if let spec = exercise.game {
                    GameExerciseView(exercise: exercise, spec: spec, chapterVM: chapterVM, persistence: persistence)
                        .id(exercise.id)
                }
            }
        }
    }

    private func solveResultContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            HStack(spacing: 8) {
                Text(exercise.prompt)
                    .font(.system(size: scaled(48), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .contentTransition(.numericText())

                Text("=")
                    .font(.system(size: scaled(48), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("?")
                    .font(.system(size: scaled(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(64), height: scaled(64))
                    .softSurface(GeniColor.card)
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
        VStack(spacing: expanded ? 44 : 28) {
            Text(exercise.missingNumberPrompt)
                .font(.system(size: scaled(44), weight: .black, design: .rounded))
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
        VStack(spacing: expanded ? 44 : 28) {
            Text(exercise.trueFalsePrompt)
                .font(.system(size: scaled(40), weight: .black, design: .rounded))
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
                            .font(.system(size: expanded ? 48 : 32, weight: .bold))
                        Text(L.s(.trueLabel))
                            .font(.system(expanded ? .largeTitle : .title3, design: .rounded, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: scaled(100))
                    .feedbackSurface(trueFalseButtonColor(for: 1, exercise: exercise))
                }
                .accessibilityIdentifier("answer.1")
                .disabled(chapterVM.showFeedback)

                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(0, persistence: persistence)
                } label: {
                    VStack(spacing: 8) {
                        Text("✗")
                            .font(.system(size: expanded ? 48 : 32, weight: .bold))
                        Text(L.s(.falseLabel))
                            .font(.system(expanded ? .largeTitle : .title3, design: .rounded, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: scaled(100))
                    .feedbackSurface(trueFalseButtonColor(for: 0, exercise: exercise))
                }
                .accessibilityIdentifier("answer.0")
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private func comparisonContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 20) {
            Text(L.s(.whichIsBigger))
                .font(.system(expanded ? .largeTitle : .title3, design: .rounded, weight: .bold))
                .foregroundStyle(.black)

            HStack(spacing: 16) {
                if let left = exercise.comparisonLeft {
                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(0, persistence: persistence)
                    } label: {
                        Text("\(left.0) \(left.1.symbol) \(left.2)")
                            .font(.system(size: expanded ? 44 : 28, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: scaled(90))
                            .feedbackSurface(comparisonBgColor(for: 0, exercise: exercise))
                    }
                    .accessibilityIdentifier("answer.0")
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
                            .font(.system(size: expanded ? 44 : 28, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: scaled(90))
                            .feedbackSurface(comparisonBgColor(for: 1, exercise: exercise))
                    }
                    .accessibilityIdentifier("answer.1")
                    .disabled(chapterVM.showFeedback)
                }
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Emoji Exercise Views

    private func emojiGrid(_ emoji: String, count: Int, columns: Int = 5) -> some View {
        let rows = (count + columns - 1) / columns
        return VStack(spacing: scaled(8)) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: scaled(8)) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < count {
                            Text(emoji)
                                .font(.system(size: scaled(40)))
                        } else {
                            Text(emoji)
                                .font(.system(size: scaled(40)))
                                .opacity(0)
                        }
                    }
                }
            }
        }
    }

    private func countingObjectsContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            Text(L.s(.howMany))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1)
                .padding(.vertical, 16)

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func visualAdditionContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            Text(L.s(.howManyTotal))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            if exercise.shouldShowEmojiCounting {
                HStack(spacing: scaled(12)) {
                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1, columns: 3)

                    Text("➕")
                        .font(.system(size: scaled(36), weight: .black, design: .rounded))

                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand2, columns: 3)
                }
                .padding(.vertical, 8)
            } else {
                Text(exercise.equationPrompt)
                    .font(.system(size: scaled(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .padding(.vertical, 16)
            }

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: scaled(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(56), height: scaled(56))
                    .softSurface(GeniColor.card)
            }

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func compareGroupsContent(_ exercise: Exercise) -> some View {
        let maxCount = max(exercise.operand1, exercise.operand2)
        let rows = (maxCount + 2) / 3 // columns=3
        let boxHeight = scaled(CGFloat(rows) * 48 + 32)

        return VStack(spacing: 20) {
            Text(L.s(.whichHasMore))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            HStack(spacing: 16) {
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(0, persistence: persistence)
                } label: {
                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1, columns: 3)
                        .padding(scaled(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: boxHeight)
                        .feedbackSurface(comparisonBgColor(for: 0, exercise: exercise))
                }
                .accessibilityIdentifier("answer.0")
                .disabled(chapterVM.showFeedback)

                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(1, persistence: persistence)
                } label: {
                    emojiGrid(exercise.emojiSymbolRight ?? "🍊", count: exercise.operand2, columns: 3)
                        .padding(scaled(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: boxHeight)
                        .feedbackSurface(comparisonBgColor(for: 1, exercise: exercise))
                }
                .accessibilityIdentifier("answer.1")
                .disabled(chapterVM.showFeedback)
            }
        }
        .padding(.vertical, 24)
    }

    private func tenFrameContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            Text(L.s(.howMany))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            let emoji = exercise.emojiSymbol ?? "⭐"
            let filled = exercise.operand1
            let cellSize = scaled(48)

            VStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { col in
                            let index = row * 5 + col
                            ZStack {
                                GeniShape(scale: 0.5)
                                    .fill(index < filled ? GeniColor.card : GeniColor.lightGray.soft(0.6))
                                    .frame(width: cellSize, height: cellSize)

                                if index < filled {
                                    Text(emoji)
                                        .font(.system(size: scaled(28)))
                                }
                            }
                            .overlay(GeniShape(scale: 0.5).stroke(GeniColor.hairline, lineWidth: 1))
                        }
                    }
                }
            }
            .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)
            .padding(.vertical, 8)

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    // MARK: - Match Connect (Draw a Line)

    private func matchConnectContent(_ exercise: Exercise) -> some View {
        let leftLabels = exercise.matchLeftLabels ?? []
        let rightLabels = exercise.matchRightLabels ?? []
        return VStack(spacing: 16) {
            Text(L.s(.matchThePairs))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .frame(maxWidth: .infinity, alignment: .leading)

            MatchConnectBoard(
                chapterVM: chapterVM,
                persistence: persistence,
                leftLabels: leftLabels,
                rightLabels: rightLabels
            )
        }
    }

    // MARK: - Number Bonds

    private func numberBondsContent(_ exercise: Exercise) -> some View {
        let isMissingWhole = exercise.numberBondMissingWhole == true
        let whole = isMissingWhole ? nil : exercise.operand1
        let leftPart = isMissingWhole ? exercise.operand1 : exercise.operand2
        let rightPart = isMissingWhole ? exercise.operand2 : nil

        return VStack(spacing: 16) {
            // Whole (top)
            if let w = whole {
                Text("\(w)")
                    .font(.system(size: scaled(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(72), height: scaled(72))
                    .softSurface(GeniColor.card)
            } else {
                Text("?")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(72), height: scaled(72))
                    .softSurface(GeniColor.yellow.soft(0.35))
            }

            // Branch lines (drawn with a simple V shape)
            Canvas { context, size in
                let midX = size.width / 2
                var leftBranch = Path()
                leftBranch.move(to: CGPoint(x: midX, y: 0))
                leftBranch.addLine(to: CGPoint(x: midX - scaled(60), y: size.height))
                context.stroke(leftBranch, with: .color(.black), lineWidth: 3)

                var rightBranch = Path()
                rightBranch.move(to: CGPoint(x: midX, y: 0))
                rightBranch.addLine(to: CGPoint(x: midX + scaled(60), y: size.height))
                context.stroke(rightBranch, with: .color(.black), lineWidth: 3)
            }
            .frame(width: scaled(200), height: scaled(40))

            // Parts (bottom)
            HStack(spacing: scaled(40)) {
                Text("\(leftPart)")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(72), height: scaled(72))
                    .softSurface(GeniColor.card)

                if let rp = rightPart {
                    Text("\(rp)")
                        .font(.system(size: scaled(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: scaled(72), height: scaled(72))
                        .softSurface(GeniColor.card)
                } else {
                    Text("?")
                        .font(.system(size: scaled(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: scaled(72), height: scaled(72))
                        .softSurface(GeniColor.yellow.soft(0.35))
                }
            }

            Spacer().frame(height: 8)

            if chapterVM.profile.ageGroup.useDragAndDrop {
                dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            } else {
                tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            }
        }
    }

    // MARK: - Dice Addition

    private func diceAdditionContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            HStack(spacing: scaled(20)) {
                DiceFaceView(value: exercise.operand1)
                Text("➕")
                    .font(.system(size: scaled(32), weight: .black, design: .rounded))
                DiceFaceView(value: exercise.operand2)
            }

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: scaled(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(56), height: scaled(56))
                    .softSurface(GeniColor.card)
            }

            if chapterVM.profile.ageGroup.useDragAndDrop {
                dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            } else {
                tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            }
        }
    }

    // MARK: - Even/Odd Sort

    private func evenOddSortContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 24) {
            if chapterVM.evenOddStep == 0 {
                // Step 1: Solve the expression
                HStack(spacing: 8) {
                    Text(exercise.prompt)
                        .font(.system(size: scaled(44), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                    Text("=")
                        .font(.system(size: scaled(44), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                    Text("?")
                        .font(.system(size: scaled(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: scaled(56), height: scaled(56))
                        .softSurface(GeniColor.card)
                }
                .padding(.vertical, 16)

                if chapterVM.profile.ageGroup.useDragAndDrop {
                    dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
                } else {
                    tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
                }
            } else {
                // Step 2: Classify as even or odd
                Text("\(exercise.correctAnswer)")
                    .font(.system(size: scaled(56), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .padding(.vertical, 8)

                HStack(spacing: 16) {
                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(0, persistence: persistence)
                    } label: {
                        VStack(spacing: 6) {
                            Text("2, 4, 6")
                                .font(.system(size: scaled(18), weight: .bold, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 0, exercise: exercise).opacity(0.75))
                            Text(L.s(.evenNumber))
                                .font(.system(size: scaled(20), weight: .black, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 0, exercise: exercise))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: scaled(90))
                        .feedbackSurface(evenOddBtnBgColor(for: 0, exercise: exercise))
                    }
                    .accessibilityIdentifier("answer.0")
                    .disabled(chapterVM.showFeedback)

                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(1, persistence: persistence)
                    } label: {
                        VStack(spacing: 6) {
                            Text("1, 3, 5")
                                .font(.system(size: scaled(18), weight: .bold, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 1, exercise: exercise).opacity(0.75))
                            Text(L.s(.oddNumber))
                                .font(.system(size: scaled(20), weight: .black, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 1, exercise: exercise))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: scaled(90))
                        .feedbackSurface(evenOddBtnBgColor(for: 1, exercise: exercise))
                    }
                    .accessibilityIdentifier("answer.1")
                    .disabled(chapterVM.showFeedback)
                }
            }
        }
    }

    private func evenOddBtnBgColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else { return GeniColor.card }
        let correctValue = exercise.correctAnswer % 2 == 0 ? 0 : 1
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) { return GeniColor.green }
        if value == selected && !chapterVM.feedbackCorrect { return GeniColor.pink.soft(0.3) }
        return GeniColor.card
    }

    private func evenOddBtnTextColor(for value: Int, exercise: Exercise) -> Color {
        evenOddBtnBgColor(for: value, exercise: exercise).readableText
    }

    // MARK: - Visual Subtraction

    private func visualSubtractionContent(_ exercise: Exercise) -> some View {
        let emoji = exercise.emojiSymbol ?? "🍎"
        let total = exercise.operand1

        return VStack(spacing: 24) {
            if exercise.shouldShowEmojiCounting {
                let remaining = exercise.correctAnswer
                let columns = min(total, 5)
                let rows = (total + columns - 1) / columns

                VStack(spacing: scaled(8)) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: scaled(8)) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < total {
                                    let isCrossedOut = index >= remaining
                                    ZStack {
                                        Text(emoji)
                                            .font(.system(size: scaled(36)))
                                            .opacity(isCrossedOut ? 0.4 : 1.0)

                                        if isCrossedOut {
                                            Text("\u{2716}")
                                                .font(.system(size: scaled(32), weight: .bold))
                                                .foregroundStyle(GeniColor.pink)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Text(exercise.equationPrompt)
                .font(.system(size: scaled(36), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)

            if chapterVM.profile.ageGroup.useDragAndDrop {
                dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            } else {
                tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
            }
        }
    }

    // MARK: - Older Age Exercise Views

    private func multiStepContent(_ exercise: Exercise) -> some View {
        VStack(spacing: expanded ? 44 : 28) {
            Text(exercise.multiStepExpression ?? "")
                .font(.system(size: scaled(40), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .padding(.vertical, 16)

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: scaled(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(56), height: scaled(56))
                    .softSurface(GeniColor.card)
            }

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func numberSequenceContent(_ exercise: Exercise) -> some View {
        let seq = exercise.sequenceNumbers ?? []

        return VStack(spacing: expanded ? 44 : 28) {
            Text(L.s(.whatComesNext))
                .font(.system(size: scaled(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            // Show sequence numbers in boxes
            HStack(spacing: 8) {
                ForEach(seq, id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: scaled(28), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: scaled(56), height: scaled(56))
                        .softSurface(GeniColor.card)
                }

                Text("?")
                    .font(.system(size: scaled(28), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(56), height: scaled(56))
                    .softSurface(GeniColor.yellow.soft(0.35))
            }
            .padding(.vertical, 16)

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func areaPerimeterContent(_ exercise: Exercise) -> some View {
        let w = exercise.gridWidth ?? 3
        let h = exercise.gridHeight ?? 3
        let isArea = exercise.operand1 == 1
        let cellSize = scaled(min(36, 200 / CGFloat(max(w, h))))

        return VStack(spacing: 20) {
            // Label: area or perimeter with visual hint
            HStack(spacing: 8) {
                Text(isArea ? "📐" : "📏")
                    .font(.system(size: 28))
                Text(isArea ? "\(w) \u{00D7} \(h)" : "2 \u{00D7} (\(w) + \(h))")
                    .font(.system(size: scaled(28), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }

            // Grid visualization
            VStack(spacing: 0) {
                ForEach(0..<h, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<w, id: \.self) { col in
                            let isEdge = row == 0 || row == h - 1 || col == 0 || col == w - 1
                            GeniShape(scale: 0.5)
                                .fill(isArea ? GeniColor.blue.soft(0.2) : (isEdge ? GeniColor.orange.soft(0.3) : GeniColor.card))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(GeniShape(scale: 0.5).stroke(GeniColor.hairline, lineWidth: 1))
                        }
                    }
                }
            }
            .overlay(GeniShape(scale: 0.5).stroke(GeniColor.hairline, lineWidth: 1))
            .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)

            // Width/height labels
            HStack {
                Text("\(w)")
                    .font(.system(size: scaled(20), weight: .bold, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }

            Text("= ?")
                .font(.system(size: scaled(32), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func fractionPickContent(_ exercise: Exercise) -> some View {
        let num = exercise.fractionNumerator ?? 1
        let den = exercise.fractionDenominator ?? 4

        return VStack(spacing: 24) {
            // Visual fraction: a bar divided into den parts, num filled
            HStack(spacing: 0) {
                ForEach(0..<den, id: \.self) { i in
                    GeniShape()
                        .fill(i < num ? GeniColor.blue.soft(0.5) : GeniColor.card)
                        .frame(width: scaled(min(60, 280 / CGFloat(den))), height: scaled(56))
                        .overlay(GeniShape().stroke(GeniColor.hairline, lineWidth: 1))
                }
            }
            .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)

            // Show fraction notation
            VStack(spacing: 2) {
                Text("?")
                    .font(.system(size: scaled(32), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Rectangle()
                    .fill(GeniColor.border)
                    .frame(width: scaled(60), height: 3)
                Text("\(den)")
                    .font(.system(size: scaled(32), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func longDivisionContent(_ exercise: Exercise) -> some View {
        let dividend = exercise.operand1
        let divisor = exercise.operand2
        let remainder = exercise.divisionRemainder ?? 0

        return VStack(spacing: 24) {
            // Classic long division layout
            HStack(spacing: 4) {
                Text("\(dividend)")
                    .font(.system(size: scaled(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("\u{00F7}")
                    .font(.system(size: scaled(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("\(divisor)")
                    .font(.system(size: scaled(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("=")
                    .font(.system(size: scaled(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("?")
                    .font(.system(size: scaled(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: scaled(56), height: scaled(56))
                    .softSurface(GeniColor.card)
            }

            if remainder > 0 {
                Text("r = \(remainder)")
                    .font(.system(size: scaled(22), weight: .bold, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GeniColor.orange.soft(0.15))
                    .clipShape(GeniShape())
                    .overlay(GeniShape().stroke(GeniColor.orange, lineWidth: 2))
            }

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func tapAnswers(_ exercise: Exercise, answers: [Int], correctValue: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: expanded ? 24 : 10), count: 2), spacing: expanded ? 24 : 10) {
            ForEach(answers, id: \.self) { option in
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.light)
                    chapterVM.submitAnswer(option, persistence: persistence)
                } label: {
                    Text("\(option)")
                        .font(.system(size: expanded ? 44 : (iPadScale.isIPad ? 28 : 22), weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: expanded ? 128 : scaled(64))
                        .feedbackSurface(answerBgColor(for: option, correct: correctValue))
                }
                .accessibilityIdentifier("answer.\(option)")
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private func dragDropAnswers(_ exercise: Exercise, answers: [Int], correctValue: Int) -> some View {
        HStack(spacing: expanded ? 24 : 10) {
            ForEach(answers, id: \.self) { option in
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.snap()
                    chapterVM.dragAnswer = option
                    chapterVM.submitAnswer(option, persistence: persistence)
                } label: {
                    Text("\(option)")
                        .font(.system(size: expanded ? 44 : (iPadScale.isIPad ? 28 : 22), weight: .black, design: .rounded))
                        .frame(width: scaled(72), height: scaled(72))
                        .feedbackSurface(dragBubbleColor(for: option, correct: correctValue))
                }
                .accessibilityIdentifier("answer.\(option)")
                .disabled(chapterVM.showFeedback)
            }
        }
    }

    private var feedbackBanner: some View {
        let fill = chapterVM.feedbackCorrect ? GeniColor.green : (chapterVM.showAnswer ? GeniColor.orange : GeniColor.pink.soft(0.3))
        return HStack(spacing: 12) {
            Text(chapterVM.feedbackCorrect ? "✅" : (chapterVM.showAnswer ? "💡" : "🔄"))
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapterVM.feedbackCorrect ? chapterVM.feedbackMessage : (chapterVM.showAnswer ? L.s(.showAnswer) : chapterVM.feedbackMessage))
                    .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .bold))

                if chapterVM.showAnswer {
                    Text("= \(chapterVM.feedbackMessage)")
                        .font(.system(.title2, design: .rounded, weight: .black))
                }
            }

            Spacer()
        }
        .padding(20)
        .feedbackSurface(fill)
        .compositingGroup()
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: expanded ? 1000 : .infinity)
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
            return GeniColor.pink.soft(0.3)
        }
        return .white
    }

    private func dragBubbleColor(for option: Int, correct: Int) -> Color {
        guard chapterVM.showFeedback else {
            return .white
        }
        if option == correct && (chapterVM.feedbackCorrect || chapterVM.showAnswer) {
            return GeniColor.green
        }
        if option == chapterVM.dragAnswer && !chapterVM.feedbackCorrect {
            return GeniColor.pink.soft(0.3)
        }
        return .white
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
            return GeniColor.pink.soft(0.3)
        }
        return GeniColor.card
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
            return GeniColor.pink.soft(0.3)
        }
        return .white
    }
}
