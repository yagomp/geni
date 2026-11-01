import SwiftUI

// Picture games for ages 4–6, all pick-one `ChoiceGameView` screens:
// finish the pattern, find the shape, spot the one that does not belong.

enum ShapeGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .patternNext: return patternNext(age: age, difficulty: difficulty)
        case .shapeFind: return shapeFind(age: age, difficulty: difficulty)
        case .oddOneOut: return oddOneOut(age: age, difficulty: difficulty)
        default: return patternNext(age: age, difficulty: difficulty)  // never routed here; safe fallback
        }
    }

    // MARK: Finish the pattern (4: A B · 5: A B B or A A B · 6: A B C)

    private static let patternPalettes: [[String]] = [
        ["🍎", "🍌", "🍇", "🍓", "🍊", "🍐"],
        ["🐸", "🐶", "🐱", "🐰", "🐥", "🐻"],
        ["🔴", "🔵", "🟢", "🟡", "🟣", "🟠"],
        ["⭐", "🌸", "🌙", "🎈", "⚽", "🚗"]
    ]

    /// Repeating patterns by age. Letters index the three pictures: 0 = A, 1 = B, 2 = C.
    private static func patternTemplates(age: Int) -> [[Int]] {
        switch age {
        case ...4: return [[0, 1]]
        case 5: return [[0, 1, 1], [0, 0, 1]]
        default: return [[0, 1, 2]]
        }
    }

    private static func patternNext(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let template = patternTemplates(age: age).randomElement()!
        let trio = Array(patternPalettes.randomElement()!.shuffled().prefix(3))
        // AB needs fewer pictures to show its pattern; five pictures is the most a 4-year-old's row needs.
        let start = template.count == 2 ? 3 : 4
        let shown = min(5, start + difficulty.rawValue)
        let row = (0..<shown).map { trio[template[$0 % template.count]] } + ["❓"]
        return pickOne(.patternNext,
                       prompt: L.t("What comes next?", no: "Hva kommer neste?", es: "¿Qué viene después?", pt: "O que vem a seguir?"),
                       scene: [row], labels: trio, correct: template[shown % template.count],
                       difficulty: difficulty)
    }

    // MARK: Find the shape (4: circle, square, triangle · 5: and star)

    enum Figure: Int, CaseIterable {
        case circle, square, triangle, star
    }

    /// Each circle with the square of the same colour. Squares and circles never share a question's colour by accident.
    static let colourPairs: [(circle: String, square: String)] = [
        (circle: "🔴", square: "🟥"), (circle: "🟠", square: "🟧"), (circle: "🟡", square: "🟨"),
        (circle: "🟢", square: "🟩"), (circle: "🔵", square: "🟦"), (circle: "🟣", square: "🟪")
    ]
    private static let triangle = "🔺"
    private static let stars = ["⭐", "🌟"]

    static func figure(of label: String) -> Figure? {
        if colourPairs.contains(where: { $0.circle == label }) { return .circle }
        if colourPairs.contains(where: { $0.square == label }) { return .square }
        if label == triangle { return .triangle }
        if stars.contains(label) { return .star }
        return nil
    }

    private static func findPrompt(_ figure: Figure) -> String {
        switch figure {
        case .circle: return L.t("Find the circle", no: "Finn sirkelen", es: "Encuentra el círculo", pt: "Encontra o círculo")
        case .square: return L.t("Find the square", no: "Finn firkanten", es: "Encuentra el cuadrado", pt: "Encontra o quadrado")
        case .triangle: return L.t("Find the triangle", no: "Finn trekanten", es: "Encuentra el triángulo", pt: "Encontra o triângulo")
        case .star: return L.t("Find the star", no: "Finn stjernen", es: "Encuentra la estrella", pt: "Encontra a estrela")
        }
    }

    private static func shapeFind(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let asked = age <= 4 ? [Figure.circle, .square, .triangle] : Figure.allCases
        let target = asked.randomElement()!
        let circleIndex = Int.random(in: 0..<colourPairs.count)
        // Harder: the square takes the circle's colour, so only the shape tells them apart.
        let squareIndex = difficulty.rawValue >= ExerciseDifficulty.harder.rawValue
            ? circleIndex
            : Int.random(in: 0..<colourPairs.count)
        // One of each shape, in Figure order, so the label position is the figure's raw value.
        let labels = [colourPairs[circleIndex].circle, colourPairs[squareIndex].square, triangle, stars.randomElement()!]
        return pickOne(.shapeFind, prompt: findPrompt(target), labels: labels, correct: target.rawValue,
                       difficulty: difficulty)
    }

    // MARK: Which one does not belong? (three from one everyday group, one from an unrelated group)

    /// Everyday groups a young child can name. No picture is in two groups, so a question built from
    /// one group plus a picture from another has exactly one answer, and no colour or shape rule competes.
    private static let pictureGroups: [String: [String]] = [
        "fruit": ["🍎", "🍌", "🍇", "🍓", "🍊", "🍐", "🍉", "🍑"],
        "vegetable": ["🥕", "🥦", "🌽", "🥔", "🍆", "🥒"],
        "animal": ["🐶", "🐱", "🐰", "🐷", "🐮", "🦁", "🐘", "🐴"],
        "sea": ["🐟", "🐙", "🐳", "🦀", "🐬", "🐠"],
        "vehicle": ["🚗", "🚕", "🚌", "🚒", "🚲", "🚂", "🚜"],
        "clothes": ["👕", "👖", "👗", "🧦", "🧢", "👟", "🧤"]
    ]

    /// Which picture groups a picture belongs to. Tests use it to check each question has one odd one out.
    static func groupNames(of label: String) -> Set<String> {
        Set(pictureGroups.filter { $0.value.contains(label) }.keys)
    }

    /// Ages 4–5 compare groups that look nothing alike; age 6 compares close groups (fruit and vegetables).
    private static func oddRules(age: Int) -> [(group: String, odd: String)] {
        switch age {
        case ...4:
            return [(group: "fruit", odd: "animal"), (group: "animal", odd: "vehicle"), (group: "vehicle", odd: "fruit")]
        case 5:
            return [(group: "fruit", odd: "animal"), (group: "animal", odd: "vehicle"),
                    (group: "clothes", odd: "fruit"), (group: "vehicle", odd: "clothes")]
        default:
            return [(group: "fruit", odd: "vegetable"), (group: "vegetable", odd: "fruit"),
                    (group: "animal", odd: "sea"), (group: "sea", odd: "animal")]
        }
    }

    private static func oddOneOut(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let rule = oddRules(age: age).randomElement()!
        let three = Array((pictureGroups[rule.group] ?? []).shuffled().prefix(3))
        let odd = (pictureGroups[rule.odd] ?? []).randomElement()!
        return pickOne(.oddOneOut,
                       prompt: L.t("Which one does not belong?", no: "Hvilken hører ikke hjemme?", es: "¿Cuál no pertenece?", pt: "Qual não pertence?"),
                       labels: three + [odd], correct: 3, difficulty: difficulty)
    }

    // MARK: Shared

    /// A pick-one game where `labels[correct]` is right. Values are label positions, so they stay distinct.
    private static func pickOne(_ kind: GameKind, prompt: String, scene: [[String]] = [], labels: [String],
                                correct: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let choices = labels.enumerated().map { GameChoice(label: $0.element, value: $0.offset) }
        return .choiceGame(kind, prompt: prompt, scene: scene, choices: choices.shuffled(),
                           correct: choices[correct], difficulty: difficulty)
    }
}

struct ShapeGameView: View {
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? ChoicePayload {
            ChoiceGameView(exercise: exercise, spec: spec, payload: payload, chapterVM: chapterVM, persistence: persistence)
        }
    }
}
