import SwiftUI

struct DiceFaceView: View {
    let value: Int
    private let size = iPadScale.value(72)
    private let dotSize = iPadScale.value(14)

    var body: some View {
        ZStack {
            Rectangle()
                .fill(GeniColor.card)
                .frame(width: size, height: size)
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))

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

    // MARK: - Emoji Exercise Views

    private func emojiGrid(_ emoji: String, count: Int, columns: Int = 5) -> some View {
        let rows = (count + columns - 1) / columns
        return VStack(spacing: iPadScale.value(8)) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: iPadScale.value(8)) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < count {
                            Text(emoji)
                                .font(.system(size: iPadScale.value(40)))
                        } else {
                            Text(emoji)
                                .font(.system(size: iPadScale.value(40)))
                                .opacity(0)
                        }
                    }
                }
            }
        }
    }

    private func countingObjectsContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            Text(L.s(.howMany))
                .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1)
                .padding(.vertical, 16)

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func visualAdditionContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            Text(L.s(.howManyTotal))
                .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            if exercise.shouldShowEmojiCounting {
                HStack(spacing: iPadScale.value(12)) {
                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1, columns: 3)

                    Text("➕")
                        .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))

                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand2, columns: 3)
                }
                .padding(.vertical, 8)
            } else {
                Text(exercise.equationPrompt)
                    .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .padding(.vertical, 16)
            }

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            }

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func compareGroupsContent(_ exercise: Exercise) -> some View {
        let maxCount = max(exercise.operand1, exercise.operand2)
        let rows = (maxCount + 2) / 3 // columns=3
        let boxHeight = iPadScale.value(CGFloat(rows) * 48 + 32)

        return VStack(spacing: 20) {
            Text(L.s(.whichHasMore))
                .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            HStack(spacing: 16) {
                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(0, persistence: persistence)
                } label: {
                    emojiGrid(exercise.emojiSymbol ?? "🍎", count: exercise.operand1, columns: 3)
                        .padding(iPadScale.value(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: boxHeight)
                        .background(comparisonBgColor(for: 0, exercise: exercise))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .disabled(chapterVM.showFeedback)

                Button {
                    guard !chapterVM.showFeedback else { return }
                    HapticManager.impact(.medium)
                    chapterVM.submitAnswer(1, persistence: persistence)
                } label: {
                    emojiGrid(exercise.emojiSymbolRight ?? "🍊", count: exercise.operand2, columns: 3)
                        .padding(iPadScale.value(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: boxHeight)
                        .background(comparisonBgColor(for: 1, exercise: exercise))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                }
                .disabled(chapterVM.showFeedback)
            }
        }
        .padding(.vertical, 24)
    }

    private func tenFrameContent(_ exercise: Exercise) -> some View {
        VStack(spacing: 28) {
            Text(L.s(.howMany))
                .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            let emoji = exercise.emojiSymbol ?? "⭐"
            let filled = exercise.operand1
            let cellSize = iPadScale.value(48)

            VStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { col in
                            let index = row * 5 + col
                            ZStack {
                                Rectangle()
                                    .fill(index < filled ? GeniColor.card : Color.gray.opacity(0.1))
                                    .frame(width: cellSize, height: cellSize)

                                if index < filled {
                                    Text(emoji)
                                        .font(.system(size: iPadScale.value(28)))
                                }
                            }
                            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                        }
                    }
                }
            }
            .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
            .padding(.vertical, 8)

            dragDropAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    // MARK: - Match Connect (Draw a Line)

    private func matchConnectContent(_ exercise: Exercise) -> some View {
        Text(L.s(.matchConnectInstruction))
            .font(.system(size: iPadScale.value(18), weight: .semibold, design: .rounded))
            .foregroundStyle(GeniColor.border)
            .multilineTextAlignment(.leading)

        Text(L.s(.matchThePairs))
            .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
            .foregroundStyle(GeniColor.border)

        let leftLabels = exercise.matchLeftLabels ?? []
        let rightLabels = exercise.matchRightLabels ?? []
        let correctIndices = exercise.correctMatchIndices ?? []
        let pairCount = leftLabels.count

        return GeometryReader { geo in
            ZStack {
                // Draw completed match lines
                Canvas { context, size in
                    for (leftIdx, rightIdx) in chapterVM.completedMatches {
                        let leftY = matchItemY(index: leftIdx, count: pairCount, height: size.height)
                        let rightY = matchItemY(index: rightIdx, count: pairCount, height: size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: size.width * 0.38, y: leftY))
                        path.addLine(to: CGPoint(x: size.width * 0.62, y: rightY))
                        context.stroke(path, with: .color(GeniColor.green), lineWidth: 4)
                    }

                    // Active drag line
                    if let sourceIdx = chapterVM.activeDragSource, let pos = chapterVM.activeDragPosition {
                        let leftY = matchItemY(index: sourceIdx, count: pairCount, height: size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: size.width * 0.38, y: leftY))
                        path.addLine(to: pos)
                        context.stroke(path, with: .color(GeniColor.blue), lineWidth: 3)
                    }

                    // Wrong match flash
                    if let wrong = chapterVM.wrongMatchPair {
                        let leftY = matchItemY(index: wrong.0, count: pairCount, height: size.height)
                        let rightY = matchItemY(index: wrong.1, count: pairCount, height: size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: size.width * 0.38, y: leftY))
                        path.addLine(to: CGPoint(x: size.width * 0.62, y: rightY))
                        context.stroke(path, with: .color(GeniColor.pink), lineWidth: 4)
                    }
                }

                HStack(spacing: 0) {
                    // Left column
                    VStack(spacing: 12) {
                        ForEach(0..<pairCount, id: \.self) { i in
                            let isMatched = chapterVM.completedMatches.contains { $0.0 == i }
                            Text(leftLabels[i])
                                .font(.system(size: iPadScale.value(20), weight: .black, design: .rounded))
                                .foregroundStyle(isMatched ? GeniColor.green : GeniColor.border)
                                .frame(maxWidth: .infinity)
                                .frame(height: iPadScale.value(52))
                                .background(GeniColor.card)
                                .overlay(Rectangle().stroke(isMatched ? GeniColor.green : GeniColor.border, lineWidth: 3))
                                .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
                                .gesture(
                                    DragGesture(minimumDistance: 5)
                                        .onChanged { value in
                                            if !isMatched {
                                                chapterVM.activeDragSource = i
                                                chapterVM.activeDragPosition = value.location
                                            }
                                        }
                                        .onEnded { value in
                                            guard chapterVM.activeDragSource == i else { return }
                                            // Hit test against right items
                                            let dropX = value.location.x
                                            let dropY = value.location.y
                                            for j in 0..<pairCount {
                                                let rightY = matchItemY(index: j, count: pairCount, height: geo.size.height)
                                                let rightCenterX = geo.size.width * 0.62
                                                let dist = sqrt(pow(dropX - rightCenterX, 2) + pow(dropY - rightY, 2))
                                                if dist < iPadScale.value(50) {
                                                    let alreadyMatched = chapterVM.completedMatches.contains { $0.1 == j }
                                                    if !alreadyMatched {
                                                        chapterVM.submitMatch(leftIndex: i, rightIndex: j, persistence: persistence)
                                                    }
                                                    break
                                                }
                                            }
                                            chapterVM.activeDragSource = nil
                                            chapterVM.activeDragPosition = nil
                                        }
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(width: geo.size.width * 0.24)

                    // Right column
                    VStack(spacing: 12) {
                        ForEach(0..<pairCount, id: \.self) { j in
                            let isMatched = chapterVM.completedMatches.contains { $0.1 == j }
                            Text(rightLabels[j])
                                .font(.system(size: iPadScale.value(22), weight: .black, design: .rounded))
                                .foregroundStyle(isMatched ? GeniColor.green : GeniColor.border)
                                .frame(maxWidth: .infinity)
                                .frame(height: iPadScale.value(52))
                                .background(GeniColor.card)
                                .overlay(Rectangle().stroke(isMatched ? GeniColor.green : GeniColor.border, lineWidth: 3))
                                .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: iPadScale.value(CGFloat(pairCount) * 64 + 20))
    }

    private func matchItemY(index: Int, count: Int, height: CGFloat) -> CGFloat {
        let itemHeight = iPadScale.value(52)
        let spacing: CGFloat = 12
        let totalHeight = CGFloat(count) * itemHeight + CGFloat(count - 1) * spacing
        let startY = (height - totalHeight) / 2
        return startY + CGFloat(index) * (itemHeight + spacing) + itemHeight / 2
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
                    .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
            } else {
                Text("?")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                    .background(GeniColor.yellow.opacity(0.3))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
            }

            // Branch lines (drawn with a simple V shape)
            Canvas { context, size in
                let midX = size.width / 2
                var leftBranch = Path()
                leftBranch.move(to: CGPoint(x: midX, y: 0))
                leftBranch.addLine(to: CGPoint(x: midX - iPadScale.value(60), y: size.height))
                context.stroke(leftBranch, with: .color(.black), lineWidth: 3)

                var rightBranch = Path()
                rightBranch.move(to: CGPoint(x: midX, y: 0))
                rightBranch.addLine(to: CGPoint(x: midX + iPadScale.value(60), y: size.height))
                context.stroke(rightBranch, with: .color(.black), lineWidth: 3)
            }
            .frame(width: iPadScale.value(200), height: iPadScale.value(40))

            // Parts (bottom)
            HStack(spacing: iPadScale.value(40)) {
                Text("\(leftPart)")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))

                if let rp = rightPart {
                    Text("\(rp)")
                        .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                        .background(GeniColor.card)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
                } else {
                    Text("?")
                        .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: iPadScale.value(72), height: iPadScale.value(72))
                        .background(GeniColor.yellow.opacity(0.3))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
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
        VStack(spacing: 28) {
            HStack(spacing: iPadScale.value(20)) {
                DiceFaceView(value: exercise.operand1)
                Text("➕")
                    .font(.system(size: iPadScale.value(32), weight: .black, design: .rounded))
                DiceFaceView(value: exercise.operand2)
            }

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
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
                        .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                    Text("=")
                        .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                    Text("?")
                        .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                        .background(GeniColor.card)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
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
                    .font(.system(size: iPadScale.value(56), weight: .black, design: .rounded))
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
                                .font(.system(size: iPadScale.value(18), weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.5))
                            Text(L.s(.evenNumber))
                                .font(.system(size: iPadScale.value(20), weight: .black, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 0, exercise: exercise))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale.value(90))
                        .background(evenOddBtnBgColor(for: 0, exercise: exercise))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                    }
                    .disabled(chapterVM.showFeedback)

                    Button {
                        guard !chapterVM.showFeedback else { return }
                        HapticManager.impact(.medium)
                        chapterVM.submitAnswer(1, persistence: persistence)
                    } label: {
                        VStack(spacing: 6) {
                            Text("1, 3, 5")
                                .font(.system(size: iPadScale.value(18), weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.5))
                            Text(L.s(.oddNumber))
                                .font(.system(size: iPadScale.value(20), weight: .black, design: .rounded))
                                .foregroundStyle(evenOddBtnTextColor(for: 1, exercise: exercise))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale.value(90))
                        .background(evenOddBtnBgColor(for: 1, exercise: exercise))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
                    }
                    .disabled(chapterVM.showFeedback)
                }
            }
        }
    }

    private func evenOddBtnBgColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else { return GeniColor.card }
        let correctValue = exercise.correctAnswer % 2 == 0 ? 0 : 1
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) { return GeniColor.green }
        if value == selected && !chapterVM.feedbackCorrect { return GeniColor.pink.opacity(0.3) }
        return GeniColor.card
    }

    private func evenOddBtnTextColor(for value: Int, exercise: Exercise) -> Color {
        guard chapterVM.showFeedback, let selected = chapterVM.selectedAnswer else { return GeniColor.border }
        let correctValue = exercise.correctAnswer % 2 == 0 ? 0 : 1
        if value == correctValue && (chapterVM.feedbackCorrect || chapterVM.showAnswer) { return .white }
        if value == selected && !chapterVM.feedbackCorrect { return GeniColor.pink }
        return GeniColor.border
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

                VStack(spacing: iPadScale.value(8)) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: iPadScale.value(8)) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < total {
                                    let isCrossedOut = index >= remaining
                                    ZStack {
                                        Text(emoji)
                                            .font(.system(size: iPadScale.value(36)))
                                            .opacity(isCrossedOut ? 0.4 : 1.0)

                                        if isCrossedOut {
                                            Text("\u{2716}")
                                                .font(.system(size: iPadScale.value(32), weight: .bold))
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
                .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
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
        VStack(spacing: 28) {
            Text(exercise.multiStepExpression ?? "")
                .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .padding(.vertical, 16)

            HStack(spacing: 8) {
                Text("=")
                    .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Text("?")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            }

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func numberSequenceContent(_ exercise: Exercise) -> some View {
        let seq = exercise.sequenceNumbers ?? []

        return VStack(spacing: 28) {
            Text(L.s(.whatComesNext))
                .font(.system(size: iPadScale.value(28), weight: .bold, design: .rounded))
                .foregroundStyle(GeniColor.border)

            // Show sequence numbers in boxes
            HStack(spacing: 8) {
                ForEach(seq, id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: iPadScale.value(28), weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                        .background(GeniColor.card)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 2, y: 2))
                }

                Text("?")
                    .font(.system(size: iPadScale.value(28), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                    .background(GeniColor.yellow.opacity(0.3))
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 2, y: 2))
            }
            .padding(.vertical, 16)

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
    }

    private func areaPerimeterContent(_ exercise: Exercise) -> some View {
        let w = exercise.gridWidth ?? 3
        let h = exercise.gridHeight ?? 3
        let isArea = exercise.operand1 == 1
        let cellSize = iPadScale.value(min(36, 200 / CGFloat(max(w, h))))

        return VStack(spacing: 20) {
            // Label: area or perimeter with visual hint
            HStack(spacing: 8) {
                Text(isArea ? "📐" : "📏")
                    .font(.system(size: 28))
                Text(isArea ? "\(w) \u{00D7} \(h)" : "2 \u{00D7} (\(w) + \(h))")
                    .font(.system(size: iPadScale.value(28), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }

            // Grid visualization
            VStack(spacing: 0) {
                ForEach(0..<h, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<w, id: \.self) { col in
                            let isEdge = row == 0 || row == h - 1 || col == 0 || col == w - 1
                            Rectangle()
                                .fill(isArea ? GeniColor.blue.opacity(0.2) : (isEdge ? GeniColor.orange.opacity(0.3) : GeniColor.card))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 1))
                        }
                    }
                }
            }
            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))

            // Width/height labels
            HStack {
                Text("\(w)")
                    .font(.system(size: iPadScale.value(20), weight: .bold, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }

            Text("= ?")
                .font(.system(size: iPadScale.value(32), weight: .black, design: .rounded))
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
                    Rectangle()
                        .fill(i < num ? GeniColor.blue.opacity(0.5) : GeniColor.card)
                        .frame(width: iPadScale.value(min(60, 280 / CGFloat(den))), height: iPadScale.value(56))
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                }
            }
            .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))

            // Show fraction notation
            VStack(spacing: 2) {
                Text("?")
                    .font(.system(size: iPadScale.value(32), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                Rectangle()
                    .fill(GeniColor.border)
                    .frame(width: iPadScale.value(60), height: 3)
                Text("\(den)")
                    .font(.system(size: iPadScale.value(32), weight: .black, design: .rounded))
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
                    .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("\u{00F7}")
                    .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("\(divisor)")
                    .font(.system(size: iPadScale.value(44), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("=")
                    .font(.system(size: iPadScale.value(40), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)

                Text("?")
                    .font(.system(size: iPadScale.value(36), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
                    .frame(width: iPadScale.value(56), height: iPadScale.value(56))
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            }

            if remainder > 0 {
                Text("r = \(remainder)")
                    .font(.system(size: iPadScale.value(22), weight: .bold, design: .rounded))
                    .foregroundStyle(GeniColor.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GeniColor.orange.opacity(0.1))
                    .overlay(Rectangle().stroke(GeniColor.orange, lineWidth: 2))
            }

            tapAnswers(exercise, answers: exercise.options, correctValue: exercise.correctAnswer)
        }
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
