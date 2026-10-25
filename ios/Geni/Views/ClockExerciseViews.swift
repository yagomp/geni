import SwiftUI

struct ClockExerciseView: View {
    let exercise: Exercise
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    @State private var setTime = ClockTime(hour: 12, minute: 0)

    init(exercise: Exercise, chapterVM: ChapterViewModel, persistence: PersistenceService) {
        self.exercise = exercise
        self.chapterVM = chapterVM
        self.persistence = persistence
        // Never begin a setting exercise with the answer already on the face.
        _setTime = State(initialValue: ClockTime(hour: exercise.correctAnswer == 0 ? 6 : 12, minute: 0))
    }

    private var target: ClockTime { exercise.clockTimes?.first ?? ClockTime(totalMinutes: exercise.correctAnswer) }

    var body: some View {
        VStack(spacing: 20) {
            Text(L.s(exercise.format == .clockSet ? .clockSet : exercise.format == .clockMatch ? .clockMatch : .clockRead))
                .font(.system(size: iPadScale.value(28), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .multilineTextAlignment(.center)
            switch exercise.format {
            case .clockMatch:
                MatchConnectBoard(chapterVM: chapterVM, persistence: persistence,
                                  leftLabels: exercise.matchLeftLabels ?? [], rightLabels: exercise.matchRightLabels ?? [],
                                  leftClocks: exercise.clockTimes)
            case .clockSet:
                Text(target.digital)
                    .font(.system(size: iPadScale.value(48), weight: .black, design: .monospaced))
                    .foregroundStyle(GeniColor.blue)
                    .accessibilityIdentifier("clock.target")
                ClockFaceView(time: setTime, minuteStep: exercise.clockMinuteStep) { setTime = $0 }
                    .frame(maxWidth: iPadScale.value(280))
                    .allowsHitTesting(!chapterVM.showFeedback && !chapterVM.isAwaitingAdvance)
                    .disabled(chapterVM.showFeedback || chapterVM.isAwaitingAdvance)
                Button(L.s(.clockCheck)) { chapterVM.submitClockTime(setTime, persistence: persistence) }
                    .buttonStyle(BrutalistButton(color: GeniColor.blue))
                    .disabled(chapterVM.showFeedback || chapterVM.isAwaitingAdvance)
                    .accessibilityIdentifier("clock.check")
            default:
                ClockFaceView(time: target)
                    .frame(maxWidth: iPadScale.value(260))
                    .accessibilityIdentifier("clock.face")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(exercise.options, id: \.self) { answer in
                        Button { chapterVM.submitAnswer(answer, persistence: persistence) } label: {
                            Text(ClockTime(totalMinutes: answer).digital)
                                .font(.system(size: iPadScale.value(28), weight: .black, design: .monospaced))
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .foregroundStyle(GeniColor.border)
                                .brutalistCard(color: answerColor(answer))
                        }
                        .buttonStyle(KidPressStyle())
                        .disabled(chapterVM.showFeedback || chapterVM.isAwaitingAdvance)
                        .accessibilityIdentifier("answer.\(answer)")
                    }
                }
            }
        }
    }

    private func answerColor(_ answer: Int) -> Color {
        if chapterVM.showFeedback {
            if answer == exercise.correctAnswer && (chapterVM.feedbackCorrect || chapterVM.showAnswer) { return GeniColor.green.soft(0.3) }
            if answer == chapterVM.selectedAnswer { return GeniColor.pink.soft(0.25) }
        }
        return .white
    }
}
