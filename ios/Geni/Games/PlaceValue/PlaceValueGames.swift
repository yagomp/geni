import SwiftUI

nonisolated struct PlaceValueNumberLinePayload: GamePayload {
    let upperBound: Int
    let tickStep: Int
    let target: Int
    let labelledValues: [Int]
    let choices: [GameChoice]

    var tickValues: [Int] { Array(stride(from: 0, through: upperBound, by: tickStep)) }
    var targetFraction: Double { Double(target) / Double(upperBound) }
}

nonisolated struct PlaceValueBlocksPayload: GamePayload {
    let tens: Int
    let ones: Int
    let isBuilding: Bool
    let choices: [GameChoice]

    var value: Int { tens * 10 + ones }
}

/// Keep the physical blocks and submitted answer in the same bounded model.
nonisolated struct PlaceValueBuildState: Equatable, Sendable {
    private(set) var tens = 0
    private(set) var ones = 0
    var value: Int { tens * 10 + ones }

    mutating func addTen() { tens = min(9, tens + 1) }
    mutating func addOne() { ones = min(9, ones + 1) }
    mutating func removeTen() { tens = max(0, tens - 1) }
    mutating func removeOne() { ones = max(0, ones - 1) }
}

enum PlaceValueGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .numberLine:
            return numberLine(age: age, difficulty: difficulty)
        case .tensOnes:
            return tensOnes(difficulty: difficulty)
        default:
            // GameFactory only routes this folder's kinds here; anything else gets a safe game
            return numberLine(age: age, difficulty: difficulty)
        }
    }

    private static func numberLine(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let upperBound: Int
        let tickStep: Int
        let labelledValues: [Int]
        switch difficulty {
        case .warmup:
            upperBound = 10
            tickStep = 1
            labelledValues = Array(0...10)
        case .normal:
            upperBound = 20
            tickStep = 1
            labelledValues = [0, 5, 10, 15, 20]
        case .harder, .challenge:
            upperBound = age >= 9 ? 1000 : 100
            tickStep = upperBound / 10
            labelledValues = difficulty == .harder ? [0, upperBound / 2, upperBound] : [0, upperBound]
        }
        let ticks = Array(stride(from: 0, through: upperBound, by: tickStep))
        // On sparse lines, ask about a hidden interior tick rather than a printed answer.
        let targets = difficulty == .warmup ? ticks : ticks.filter { !labelledValues.contains($0) }
        let target = targets.randomElement()!
        let choices = choices(answer: target, candidates: ticks, count: difficulty == .warmup ? 3 : 4)
        let payload = PlaceValueNumberLinePayload(upperBound: upperBound, tickStep: tickStep, target: target,
                                                 labelledValues: labelledValues, choices: choices)
        return Exercise(
            game: GameSpec(kind: .numberLine,
                           prompt: L.t("Which number is the frog on?", no: "Hvilket tall står frosken på?",
                                       es: "¿En qué número está la rana?", pt: "Em que número está a rã?"),
                           answerText: String(target), payload: payload),
            correctAnswer: target, options: choices.map(\.value), difficulty: difficulty
        )
    }

    private static func tensOnes(difficulty: ExerciseDifficulty) -> Exercise {
        let isBuilding = difficulty == .harder || difficulty == .challenge
        let tens = Int.random(in: difficulty == .warmup ? 1...4 : 1...9)
        let ones = Int.random(in: 0...9)
        let value = tens * 10 + ones
        let options = isBuilding ? [] : choices(answer: value, candidates: Array(0...99),
                                                count: difficulty == .warmup ? 3 : 4,
                                                preferred: [value - 10, value + 10, tens + ones, ones * 10 + tens, value - 1, value + 1])
        let payload = PlaceValueBlocksPayload(tens: tens, ones: ones, isBuilding: isBuilding, choices: options)
        let prompt = isBuilding
            ? L.t("Build \(value)", no: "Bygg \(value)", es: "Forma el \(value)", pt: "Constrói o \(value)")
            : L.t("What number is this?", no: "Hvilket tall er dette?",
                  es: "¿Qué número es?", pt: "Que número é este?")
        return Exercise(game: GameSpec(kind: .tensOnes, prompt: prompt, answerText: String(value), payload: payload),
                        correctAnswer: value, options: options.map(\.value), difficulty: difficulty)
    }

    private static func choices(answer: Int, candidates: [Int], count: Int, preferred: [Int] = []) -> [GameChoice] {
        let allowed = Set(candidates)
        var values = [answer]
        for value in preferred.shuffled() + candidates.shuffled() where allowed.contains(value) && !values.contains(value) {
            values.append(value)
            if values.count == count { break }
        }
        return values.shuffled().map { GameChoice(label: String($0), value: $0) }
    }
}

struct PlaceValueGameView: View {
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    @Environment(\.geniExpandedLayout) private var expanded
    @State private var build = PlaceValueBuildState()

    var body: some View {
        VStack(spacing: expanded ? 28 : 16) {
            GameQuestion(text: spec.prompt)
            if let payload = spec.payload as? PlaceValueNumberLinePayload {
                GameSceneCard {
                    PlaceValueNumberLineDrawing(payload: payload)
                        .frame(height: expanded ? 250 : iPadScale.value(150))
                }
                GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
            } else if let payload = spec.payload as? PlaceValueBlocksPayload {
                if payload.isBuilding {
                    builder
                    GameSubmitButton(value: build.value, chapterVM: chapterVM, persistence: persistence, isEnabled: build.value > 0)
                        .accessibilityIdentifier("answer.\(build.value)")
                } else {
                    GameSceneCard {
                        PlaceValueBlocksDrawing(tens: payload.tens, ones: payload.ones)
                            .frame(height: expanded ? 290 : iPadScale.value(168))
                    }
                    GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
                }
            }
        }
    }

    private var builder: some View {
        GameSceneCard {
            GeometryReader { geometry in
                let tensWidth = (geometry.size.width - 12) * 0.65
                let onesWidth = geometry.size.width - tensWidth - 12
                let blockHeight: CGFloat = expanded ? 245 : iPadScale.value(148)
                let unit = min(blockHeight / 10, (tensWidth - 28) / 9)
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(spacing: 12) {
                        Button { change { build.removeTen() } } label: {
                            PlaceValueBlockGroup(count: build.tens, isTens: true, unit: unit)
                                .frame(width: tensWidth, height: blockHeight)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(KidPressStyle())
                        .disabled(build.tens == 0 || chapterVM.showFeedback)
                        .accessibilityLabel(L.t("Remove a ten", no: "Ta bort en tier", es: "Quita una decena", pt: "Retira uma dezena"))
                        .accessibilityIdentifier("placeValue.removeTen")
                        addButton(isTens: true, enabled: build.tens < 9) { build.addTen() }
                    }
                    .frame(width: tensWidth)
                    VStack(spacing: 12) {
                        Button { change { build.removeOne() } } label: {
                            PlaceValueBlockGroup(count: build.ones, isTens: false, unit: unit)
                                .frame(width: onesWidth, height: blockHeight)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(KidPressStyle())
                        .disabled(build.ones == 0 || chapterVM.showFeedback)
                        .accessibilityLabel(L.t("Remove a one", no: "Ta bort en ener", es: "Quita una unidad", pt: "Retira uma unidade"))
                        .accessibilityIdentifier("placeValue.removeOne")
                        addButton(isTens: false, enabled: build.ones < 9) { build.addOne() }
                    }
                    .frame(width: onesWidth)
                }
            }
            .frame(height: expanded ? 345 : iPadScale.value(148) + 12 + iPadScale.value(56))
            .accessibilityValue(L.t("\(build.tens) tens, \(build.ones) ones", no: "\(build.tens) tiere, \(build.ones) enere",
                                     es: "\(build.tens) decenas, \(build.ones) unidades", pt: "\(build.tens) dezenas, \(build.ones) unidades"))
        }
    }

    private func addButton(isTens: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { change(action) } label: {
            HStack(spacing: expanded ? 20 : 12) {
                PlaceValueBlockGroup(count: 1, isTens: isTens, unit: isTens ? (expanded ? 7 : 4) : (expanded ? 24 : 16))
                    .frame(width: expanded ? 26 : 20, height: expanded ? 72 : 42)
                    .accessibilityHidden(true)
                Image(systemName: "plus")
                    .font(.system(size: expanded ? 36 : iPadScale.value(24), weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: expanded ? 88 : iPadScale.value(56))
        }
        .buttonStyle(GameTileStyle(fill: enabled ? GeniColor.card : GeniColor.lightGray))
        .disabled(!enabled || chapterVM.showFeedback)
        .accessibilityLabel(isTens
                            ? L.t("Add a ten", no: "Legg til en tier", es: "Añade una decena", pt: "Adiciona uma dezena")
                            : L.t("Add a one", no: "Legg til en ener", es: "Añade una unidad", pt: "Adiciona uma unidade"))
        .accessibilityIdentifier(isTens ? "placeValue.addTen" : "placeValue.addOne")
    }

    private func change(_ action: () -> Void) {
        guard !chapterVM.showFeedback else { return }
        HapticManager.impact(.light)
        action()
    }
}

private struct PlaceValueNumberLineDrawing: View {
    let payload: PlaceValueNumberLinePayload
    @Environment(\.geniExpandedLayout) private var expanded

    var body: some View {
        Canvas { context, size in
            let scale: CGFloat = expanded ? 1.6 : iPadScale.value(1)
            let inset: CGFloat = payload.upperBound == 1000 ? 32 * scale : 20 * scale
            let width = max(1, size.width - 2 * inset)
            let baseline = size.height * 0.58
            func x(_ value: Int) -> CGFloat { inset + width * CGFloat(value) / CGFloat(payload.upperBound) }
            var line = Path()
            line.move(to: CGPoint(x: inset, y: baseline))
            line.addLine(to: CGPoint(x: size.width - inset, y: baseline))
            context.stroke(line, with: .color(GeniColor.border), style: StrokeStyle(lineWidth: 4 * scale, lineCap: .round))
            for tick in payload.tickValues {
                var mark = Path()
                mark.move(to: CGPoint(x: x(tick), y: baseline - 9 * scale))
                mark.addLine(to: CGPoint(x: x(tick), y: baseline + 9 * scale))
                context.stroke(mark, with: .color(GeniColor.border), style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))
                if payload.labelledValues.contains(tick) {
                    context.draw(Text(String(tick)).font(.system(size: 22 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border), at: CGPoint(x: x(tick), y: baseline + 30 * scale))
                }
            }
            let frogX = x(payload.target)
            let frogY = baseline - 40 * scale
            // An arrow tip touches the exact tick, even when the frog is wider than the tick spacing.
            var pointer = Path()
            pointer.move(to: CGPoint(x: frogX - 7 * scale, y: baseline - 19 * scale))
            pointer.addLine(to: CGPoint(x: frogX + 7 * scale, y: baseline - 19 * scale))
            pointer.addLine(to: CGPoint(x: frogX, y: baseline - 3 * scale))
            pointer.closeSubpath()
            context.fill(pointer, with: .color(GeniColor.green))
            context.stroke(pointer, with: .color(GeniColor.border), lineWidth: 2 * scale)
            let face = Path(ellipseIn: CGRect(x: frogX - 21 * scale, y: frogY - 13 * scale, width: 42 * scale, height: 30 * scale))
            context.fill(face, with: .color(GeniColor.green))
            context.stroke(face, with: .color(GeniColor.border), lineWidth: 2.5 * scale)
            for direction in [CGFloat(-1), CGFloat(1)] {
                let eye = Path(ellipseIn: CGRect(x: frogX + direction * 12 * scale - 7 * scale,
                                               y: frogY - 23 * scale, width: 14 * scale, height: 16 * scale))
                context.fill(eye, with: .color(GeniColor.card))
                context.stroke(eye, with: .color(GeniColor.border), lineWidth: 2.5 * scale)
                context.fill(Path(ellipseIn: CGRect(x: frogX + direction * 12 * scale - 2 * scale,
                                                    y: frogY - 18 * scale, width: 5 * scale, height: 6 * scale)),
                             with: .color(GeniColor.border))
            }
            var smile = Path()
            smile.move(to: CGPoint(x: frogX - 9 * scale, y: frogY + 1 * scale))
            smile.addQuadCurve(to: CGPoint(x: frogX + 9 * scale, y: frogY + 1 * scale),
                               control: CGPoint(x: frogX, y: frogY + 11 * scale))
            context.stroke(smile, with: .color(GeniColor.border), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("Number line from 0 to \(payload.upperBound)", no: "Tallinje fra 0 til \(payload.upperBound)",
                                es: "Recta numérica de 0 a \(payload.upperBound)", pt: "Reta numérica de 0 a \(payload.upperBound)"))
        .accessibilityValue(L.t("The frog is \(payload.target / payload.tickStep) steps from zero. Each step is \(payload.tickStep).",
                               no: "Frosken er \(payload.target / payload.tickStep) steg fra null. Hvert steg er \(payload.tickStep).",
                               es: "La rana está a \(payload.target / payload.tickStep) pasos del cero. Cada paso vale \(payload.tickStep).",
                               pt: "A rã está a \(payload.target / payload.tickStep) passos do zero. Cada passo vale \(payload.tickStep)."))
    }
}

private struct PlaceValueBlocksDrawing: View {
    let tens: Int
    let ones: Int

    var body: some View {
        GeometryReader { geometry in
            let tensWidth = (geometry.size.width - 12) * 0.65
            let unit = min((geometry.size.height - 8) / 10, (tensWidth - 28) / 9)
            HStack(spacing: 12) {
                PlaceValueBlockGroup(count: tens, isTens: true, unit: unit)
                    .frame(width: tensWidth)
                PlaceValueBlockGroup(count: ones, isTens: false, unit: unit)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("\(tens) tens, \(ones) ones", no: "\(tens) tiere, \(ones) enere",
                                es: "\(tens) decenas, \(ones) unidades", pt: "\(tens) dezenas, \(ones) unidades"))
    }
}

/// Each blue rod has exactly ten square cells; orange units use the same cell size.
private struct PlaceValueBlockGroup: View {
    let count: Int
    let isTens: Bool
    let unit: CGFloat

    var body: some View {
        Canvas { context, size in
            let gap = max(3, unit * 0.25)
            let columns = isTens ? count : min(3, count)
            let rows = isTens ? 1 : (count + 2) / 3
            let groupWidth = CGFloat(columns) * unit + CGFloat(max(0, columns - 1)) * gap
            let groupHeight = isTens ? unit * 10 : CGFloat(rows) * unit + CGFloat(max(0, rows - 1)) * gap
            let startX = (size.width - groupWidth) / 2
            let startY = (size.height - groupHeight) / 2
            for index in 0..<count {
                let column = isTens ? index : index % 3
                let row = isTens ? 0 : index / 3
                let rect = CGRect(x: startX + CGFloat(column) * (unit + gap), y: startY + CGFloat(row) * (unit + gap),
                                  width: unit, height: isTens ? unit * 10 : unit)
                let shape = Path(rect)
                context.fill(shape, with: .color(isTens ? GeniColor.blue : GeniColor.orange))
                context.stroke(shape, with: .color(GameStyle.hairline), lineWidth: 1)
                if isTens {
                    var divisions = Path()
                    for cell in 1..<10 {
                        let y = rect.minY + CGFloat(cell) * unit
                        divisions.move(to: CGPoint(x: rect.minX, y: y))
                        divisions.addLine(to: CGPoint(x: rect.maxX, y: y))
                    }
                    context.stroke(divisions, with: .color(GeniColor.card.soft(0.7)), lineWidth: 1)
                }
            }
        }
    }
}
