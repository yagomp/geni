import Foundation

/// The five solids; the raw value is what a picture tile answers with.
nonisolated enum Solid: Int, Sendable, CaseIterable {
    case cube, cylinder, sphere, cone, pyramid

    var name: String {
        switch self {
        case .cube: return L.t("Cube", no: "Kube", es: "Cubo", pt: "Cubo")
        case .cylinder: return L.t("Cylinder", no: "Sylinder", es: "Cilindro", pt: "Cilindro")
        case .sphere: return L.t("Sphere", no: "Kule", es: "Esfera", pt: "Esfera")
        case .cone: return L.t("Cone", no: "Kjegle", es: "Cono", pt: "Cone")
        case .pyramid: return L.t("Pyramid", no: "Pyramide", es: "Pirámide", pt: "Pirâmide")
        }
    }

    /// "a cube", "en kube", "un cubo", "um cubo".
    var withArticle: String {
        switch self {
        case .cube: return L.t("a cube", no: "en kube", es: "un cubo", pt: "um cubo")
        case .cylinder: return L.t("a cylinder", no: "en sylinder", es: "un cilindro", pt: "um cilindro")
        case .sphere: return L.t("a sphere", no: "en kule", es: "una esfera", pt: "uma esfera")
        case .cone: return L.t("a cone", no: "en kjegle", es: "un cono", pt: "um cone")
        case .pyramid: return L.t("a pyramid", no: "en pyramide", es: "una pirámide", pt: "uma pirâmide")
        }
    }

    /// Flat-sided solids have corners, edges and faces; round ones only have flat faces to count.
    var corners: Int {
        switch self {
        case .cube: return 8
        case .pyramid: return 5
        case .cone: return 1
        case .cylinder, .sphere: return 0
        }
    }

    /// Faces of the flat-sided solids; for round ones, the flat faces.
    var faces: Int {
        switch self {
        case .cube: return 6
        case .pyramid: return 5
        case .cylinder: return 2
        case .cone: return 1
        case .sphere: return 0
        }
    }

    /// Only for the flat-sided solids (a cylinder's edges are curved, so we don't ask).
    var edges: Int? {
        switch self {
        case .cube: return 12
        case .pyramid: return 8
        default: return nil
        }
    }

    var isFlatSided: Bool { self == .cube || self == .pyramid }
}

nonisolated enum SolidProperty: Sendable, Hashable {
    case corners, faces, edges, flatFaces
}

extension CalendarGames {
    private enum SolidQuestion {
        case rolls
        case name
        case count(SolidProperty, Solid)
    }

    static func count(_ property: SolidProperty, of solid: Solid) -> Int {
        switch property {
        case .corners: return solid.corners
        case .faces, .flatFaces: return solid.faces
        case .edges: return solid.edges ?? 0
        }
    }

    static func makeShapes3D(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch solidQuestion(difficulty) {
        case .rolls: return makeRolls(difficulty: difficulty)
        case .name: return makeSolidName(difficulty: difficulty)
        case let .count(property, solid): return makeSolidCount(property, solid, difficulty: difficulty)
        }
    }

    private static func solidQuestion(_ difficulty: ExerciseDifficulty) -> SolidQuestion {
        let easy: [SolidQuestion] = [.count(.corners, .cube), .count(.faces, .cube), .count(.flatFaces, .cylinder),
                                     .count(.corners, .cone), .count(.flatFaces, .cone), .count(.corners, .sphere),
                                     .count(.corners, .cylinder), .count(.flatFaces, .sphere)]
        let mid: [SolidQuestion] = [.count(.corners, .pyramid), .count(.faces, .pyramid), .count(.edges, .cube)]
        let hard: [SolidQuestion] = [.count(.edges, .pyramid), .count(.edges, .cube), .count(.corners, .pyramid),
                                     .count(.faces, .pyramid), .count(.corners, .cube), .count(.faces, .cube)]
        switch difficulty {
        case .warmup: return [.rolls, .name, .rolls, .name, .count(.corners, .cube)].randomElement()!
        case .normal: return ([.rolls, .name] + easy).randomElement()!
        case .harder: return (easy + mid).randomElement()!
        case .challenge: return hard.randomElement()!
        }
    }

    private static func makeRolls(difficulty: ExerciseDifficulty) -> Exercise {
        // Both a ball and a can roll; the flat-sided solids never do.
        let answer: Solid = [.sphere, .cylinder].randomElement()!
        let choices = [answer, .cube, .pyramid].shuffled().map { GameChoice(label: $0.name, value: $0.rawValue) }
        let payload = CalendarPayload(scene: .emoji("🛝"), style: .solids, choices: choices, fact: .rolls(answer: answer))
        return exercise(.shapes3D, prompt: L.t("Which one rolls?", no: "Hvilken ruller?", es: "¿Cuál rueda?", pt: "Qual rola?"),
                        answerText: answer.name, payload: payload, correct: answer.rawValue, difficulty: difficulty)
    }

    private static func makeSolidName(difficulty: ExerciseDifficulty) -> Exercise {
        let answer = Solid.allCases.randomElement()!
        let count = difficulty == .warmup ? 3 : 4
        let wrong = Solid.allCases.filter { $0 != answer }.shuffled().prefix(count - 1)
        let choices = ([answer] + wrong).shuffled().map { GameChoice(label: $0.name, value: $0.rawValue) }
        let payload = CalendarPayload(scene: .solid(answer), style: .text, choices: choices, fact: .name(answer))
        return exercise(.shapes3D, prompt: L.t("What shape is this?", no: "Hvilken form er dette?", es: "¿Qué figura es?", pt: "Que forma é esta?"),
                        answerText: answer.name, payload: payload, correct: answer.rawValue, difficulty: difficulty)
    }

    private static func makeSolidCount(_ property: SolidProperty, _ solid: Solid, difficulty: ExerciseDifficulty) -> Exercise {
        let answer = count(property, of: solid)
        // Mix-ups first: a cube's 6 faces, 8 corners and 12 edges are the numbers children swap.
        var related = [SolidProperty.corners, .faces, .edges].compactMap { p -> Int? in
            solid.isFlatSided ? count(p, of: solid) : nil
        }
        related = Array(Set(related.filter { $0 != answer })).shuffled()
        var wrong = Array(related.prefix(2))
        for number in (0...14).filter({ abs($0 - answer) <= 3 && $0 != answer && !wrong.contains($0) }).shuffled() where wrong.count < 3 {
            wrong.append(number)
        }
        let choices = ([answer] + wrong).shuffled().map { GameChoice(label: "\($0)", value: $0) }
        let payload = CalendarPayload(scene: .solid(solid), style: .text, choices: choices,
                                      fact: .count(property, solid, answer: answer))
        return exercise(.shapes3D, prompt: countPrompt(property, solid), answerText: "\(answer)", payload: payload,
                        correct: answer, difficulty: difficulty)
    }

    static func countPrompt(_ property: SolidProperty, _ solid: Solid) -> String {
        let x = solid.withArticle
        switch property {
        case .corners:
            return L.t("How many corners does \(x) have?", no: "Hvor mange hjørner har \(x)?",
                       es: "¿Cuántos vértices tiene \(x)?", pt: "Quantos vértices tem \(x)?")
        case .faces:
            return L.t("How many faces does \(x) have?", no: "Hvor mange sideflater har \(x)?",
                       es: "¿Cuántas caras tiene \(x)?", pt: "Quantas faces tem \(x)?")
        case .edges:
            return L.t("How many edges does \(x) have?", no: "Hvor mange kanter har \(x)?",
                       es: "¿Cuántas aristas tiene \(x)?", pt: "Quantas arestas tem \(x)?")
        case .flatFaces:
            return L.t("How many flat faces does \(x) have?", no: "Hvor mange flate sider har \(x)?",
                       es: "¿Cuántas caras planas tiene \(x)?", pt: "Quantas faces planas tem \(x)?")
        }
    }
}
