import SwiftUI

struct MistakeReviewView: View {
    let mistakes: [ExerciseResult]
    let onDismiss: () -> Void

    @State private var reviewedIds: Set<String> = []
    @State private var currentFeedback: (id: String, correct: Bool)? = nil

    private var sortedMistakes: [ExerciseResult] {
        // Group by prompt, prioritize repeated mistakes
        let grouped = Dictionary(grouping: mistakes, by: \.prompt)
        let sorted = grouped.sorted { $0.value.count > $1.value.count }
        // Take one representative from each group, deduped
        var seen = Set<String>()
        var result: [ExerciseResult] = []
        for (_, group) in sorted {
            if let first = group.first, !seen.contains(first.prompt) {
                seen.insert(first.prompt)
                result.append(first)
            }
        }
        return result
    }

    private var groupedByOperation: [(MathOperation, [ExerciseResult])] {
        let grouped = Dictionary(grouping: sortedMistakes, by: \.operationType)
        return MathOperation.allCases.compactMap { op in
            guard let items = grouped[op], !items.isEmpty else { return nil }
            return (op, items)
        }
    }

    private var reviewedCount: Int {
        reviewedIds.count
    }

    private var totalCount: Int {
        sortedMistakes.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Text(L.s(.back))
                        .font(.system(size: iPadScale.isIPad ? 20 : 16, weight: .bold, design: .rounded))
                }

                Spacer()

                Text("\(reviewedCount)/\(totalCount)")
                    .font(.system(size: iPadScale.isIPad ? 20 : 16, weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, iPadScale.padding)
            .padding(.vertical, 12)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(GeniColor.lightGray)
                        .frame(height: 8)

                    Rectangle()
                        .fill(GeniColor.green)
                        .frame(width: totalCount > 0 ? geo.size.width * CGFloat(reviewedCount) / CGFloat(totalCount) : 0, height: 8)
                        .animation(.spring(response: 0.3), value: reviewedCount)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, iPadScale.padding)

            if reviewedCount == totalCount && totalCount > 0 {
                // All done
                VStack(spacing: 16) {
                    Spacer()
                    Text("⭐")
                        .font(.system(size: 64))
                    Text(L.s(.reviewComplete))
                        .font(.system(size: iPadScale.isIPad ? 32 : 24, weight: .black, design: .rounded))
                    Text(L.s(.allReviewed))
                        .font(.system(size: iPadScale.isIPad ? 20 : 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L.s(.done), action: onDismiss)
                        .buttonStyle(BrutalistButton(color: GeniColor.green))
                        .padding(.horizontal, iPadScale.padding)
                    Spacer().frame(height: 40)
                }
            } else {
                // Problem list
                ScrollView {
                    VStack(spacing: iPadScale.isIPad ? 24 : 16) {
                        ForEach(groupedByOperation, id: \.0) { operation, items in
                            VStack(alignment: .leading, spacing: iPadScale.isIPad ? 14 : 10) {
                                // Section header
                                HStack(spacing: 8) {
                                    Text(operation.emoji)
                                        .font(.system(size: iPadScale.isIPad ? 22 : 18))
                                    Text(operationName(operation))
                                        .font(.system(size: iPadScale.isIPad ? 20 : 16, weight: .black, design: .rounded))
                                }
                                .padding(.horizontal, 4)

                                ForEach(items, id: \.id) { mistake in
                                    MistakeProblemCard(
                                        mistake: mistake,
                                        isReviewed: reviewedIds.contains(mistake.id),
                                        feedback: currentFeedback?.id == mistake.id ? currentFeedback : nil,
                                        onAnswer: { answer in
                                            handleAnswer(answer: answer, mistake: mistake)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, iPadScale.padding)
                    .padding(.vertical, iPadScale.isIPad ? 20 : 14)
                }
            }
        }
        .background(GeniColor.background)
    }

    private func handleAnswer(answer: Int, mistake: ExerciseResult) {
        let isCorrect = answer == mistake.correctAnswer
        currentFeedback = (id: mistake.id, correct: isCorrect)

        if isCorrect {
            HapticManager.correctAnswer()
        } else {
            HapticManager.wrongAnswer()
        }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation {
                reviewedIds.insert(mistake.id)
                currentFeedback = nil
            }
        }
    }

    private func operationName(_ op: MathOperation) -> String {
        switch op {
        case .addition: return L.s(.addition)
        case .subtraction: return L.s(.subtraction)
        case .multiplication: return L.s(.multiplication)
        case .division: return L.s(.division)
        }
    }
}

private struct MistakeProblemCard: View {
    let mistake: ExerciseResult
    let isReviewed: Bool
    let feedback: (id: String, correct: Bool)?
    let onAnswer: (Int) -> Void

    private var options: [Int] {
        guard mistake.correctAnswer != 0 else { return [] }
        var opts = Set<Int>()
        opts.insert(mistake.correctAnswer)
        let range = max(5, abs(mistake.correctAnswer))
        while opts.count < 4 {
            let offset = Int.random(in: 1...range)
            let wrong = Bool.random() ? mistake.correctAnswer + offset : mistake.correctAnswer - offset
            if wrong != mistake.correctAnswer && wrong >= 0 {
                opts.insert(wrong)
            }
        }
        return Array(opts).shuffled()
    }

    var body: some View {
        VStack(spacing: iPadScale.isIPad ? 12 : 8) {
            // Prompt
            HStack {
                Text(mistake.prompt)
                    .font(.system(size: iPadScale.isIPad ? 24 : 18, weight: .black, design: .rounded))

                Spacer()

                if isReviewed {
                    Text("✅")
                        .font(.system(size: iPadScale.isIPad ? 22 : 18))
                }
            }

            if !isReviewed && mistake.correctAnswer != 0 {
                // Answer options
                HStack(spacing: iPadScale.isIPad ? 12 : 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onAnswer(option)
                        } label: {
                            Text("\(option)")
                                .font(.system(size: iPadScale.isIPad ? 22 : 17, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, iPadScale.isIPad ? 14 : 10)
                                .background(buttonColor(for: option))
                                .overlay(
                                    Rectangle()
                                        .stroke(GeniColor.border, lineWidth: 2)
                                )
                        }
                        .disabled(feedback != nil)
                    }
                }
            } else if !isReviewed {
                // Legacy data without correctAnswer
                Text("→ \(mistake.prompt)")
                    .font(.system(size: iPadScale.isIPad ? 18 : 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(iPadScale.isIPad ? 16 : 12)
        .brutalistCard(color: isReviewed ? GeniColor.green.opacity(0.1) : GeniColor.card)
    }

    private func buttonColor(for option: Int) -> Color {
        guard let fb = feedback else { return GeniColor.lightGray }
        if option == mistake.correctAnswer {
            return GeniColor.green.opacity(0.7)
        }
        if !fb.correct && option == mistake.userAnswer {
            return GeniColor.pink.opacity(0.3)
        }
        return GeniColor.lightGray
    }
}
