import Foundation

nonisolated struct StoryGroupsPicture: Sendable {
    let groups: Int
    let itemsPerGroup: Int
    let item: String
    var character: String? = nil
    var showsCalculation = false

    var total: Int { groups * itemsPerGroup }
}

nonisolated struct StorySharingPicture: Sendable {
    let total: Int
    let friends: Int
    let item: String
    var character: String? = nil
    var asksForRemainder = false

    var each: Int { total / friends }
    var remainder: Int { total % friends }
}

nonisolated enum StoryPicture: Sendable {
    case groups(StoryGroupsPicture)
    case sharing(StorySharingPicture)
}

nonisolated enum StoryOperation: Int, Sendable {
    // Values identify calculation tiles, rather than their numerical results.
    case times = 1, share, add, subtract
}

nonisolated struct StoryCalculation: Sendable {
    let left: Int
    let right: Int
    let operation: StoryOperation

    var label: String {
        let symbol: String
        switch operation {
        case .times: symbol = "×"
        case .share: symbol = "÷"
        case .add: symbol = "+"
        case .subtract: symbol = "−"
        }
        return "\(left) \(symbol) \(right)"
    }
}

nonisolated enum StoryContext: CaseIterable, Sendable {
    case fairyTale, outing, sport, market
}

nonisolated struct StoryProblem: Sendable {
    let context: StoryContext
    let groups: Int
    let itemsPerGroup: Int
    let operation: StoryOperation

    var total: Int { groups * itemsPerGroup }

    var item: String {
        switch context {
        case .fairyTale, .market: return "🍎"
        case .outing: return "🥪"
        case .sport: return "🍊"
        }
    }

    var character: String {
        switch context {
        case .fairyTale: return L.selectedLanguage == .norwegian ? "🐐" : "🐷"
        case .outing: return "🎒"
        case .sport: return L.selectedLanguage == .norwegian ? "⛷️" : "⚽️"
        case .market: return "🧺"
        }
    }

    var prompt: String {
        let n = groups, m = itemsPerGroup, t = total
        switch (context, operation) {
        case (.fairyTale, .times):
            return L.t("3 little pigs pack \(m) apples each. How many apples?",
                       no: "Bukkene Bruse får \(m) epler hver. Hvor mange får de tre?",
                       es: "Los tres cerditos llevan \(m) manzanas cada uno. ¿Cuántas hay?",
                       pt: "Os três porquinhos levam \(m) maçãs cada um. Quantas são?")
        case (.fairyTale, _):
            return L.t("3 little pigs share \(t) apples equally. How many each?",
                       no: "Bukkene Bruse deler \(t) epler likt. Hvor mange får hver?",
                       es: "Los tres cerditos reparten \(t) manzanas por igual. ¿Cuántas para cada uno?",
                       pt: "Os três porquinhos dividem \(t) maçãs igualmente. Quantas para cada um?")
        case (.outing, .times):
            return L.t("\(n) friends pack \(m) sandwiches each for a picnic. How many sandwiches?",
                       no: "\(n) venner har \(m) brødskiver hver i matpakka. Hvor mange brødskiver?",
                       es: "\(n) amigos llevan \(m) bocadillos cada uno de excursión. ¿Cuántos bocadillos hay?",
                       pt: "\(n) amigos levam \(m) sandes cada um para o piquenique. Quantas sandes são?")
        case (.outing, _):
            return L.t("\(n) friends share \(t) picnic sandwiches equally. How many each?",
                       no: "\(n) venner deler \(t) brødskiver likt på tur. Hvor mange får hver?",
                       es: "\(n) amigos reparten \(t) bocadillos por igual. ¿Cuántos para cada uno?",
                       pt: "\(n) amigos dividem \(t) sandes igualmente no piquenique. Quantas para cada um?")
        case (.sport, .times):
            return L.t("\(n) football teams bring \(m) oranges each. How many oranges?",
                       no: "\(n) skiløpere tar med \(m) appelsiner hver. Hvor mange appelsiner?",
                       es: "\(n) equipos de fútbol llevan \(m) naranjas cada uno. ¿Cuántas naranjas hay?",
                       pt: "\(n) equipas de futebol levam \(m) laranjas cada uma. Quantas laranjas são?")
        case (.sport, _):
            return L.t("\(n) football teams share \(t) oranges equally. How many per team?",
                       no: "\(n) skiløpere deler \(t) appelsiner likt. Hvor mange får hver?",
                       es: "\(n) equipos de fútbol reparten \(t) naranjas por igual. ¿Cuántas por equipo?",
                       pt: "\(n) equipas de futebol dividem \(t) laranjas igualmente. Quantas por equipa?")
        case (.market, .times):
            return L.t("\(n) picnic baskets hold \(m) apples each. How many apples?",
                       no: "\(n) kurver i Kardemomme by har \(m) epler hver. Hvor mange epler?",
                       es: "\(n) cestas del mercado tienen \(m) manzanas cada una. ¿Cuántas manzanas hay?",
                       pt: "\(n) cestos do mercado têm \(m) maçãs cada um. Quantas maçãs são?")
        case (.market, _):
            return L.t("Share \(t) apples equally among \(n) picnic baskets. How many per basket?",
                       no: "Fordel \(t) epler likt i \(n) kurver i Kardemomme by. Hvor mange i hver?",
                       es: "Reparte \(t) manzanas por igual en \(n) cestas del mercado. ¿Cuántas por cesta?",
                       pt: "Divide \(t) maçãs igualmente por \(n) cestos do mercado. Quantas por cesto?")
        }
    }

    var calculations: [StoryCalculation] {
        if operation == .times {
            return [StoryCalculation(left: groups, right: itemsPerGroup, operation: .times),
                    StoryCalculation(left: groups, right: itemsPerGroup, operation: .add),
                    StoryCalculation(left: total, right: groups, operation: .subtract)]
        }
        return [StoryCalculation(left: total, right: groups, operation: .share),
                StoryCalculation(left: total, right: groups, operation: .subtract),
                StoryCalculation(left: total, right: groups, operation: .times)]
    }
}

nonisolated struct StoryPayload: GamePayload {
    let picture: StoryPicture
    let choices: [GameChoice]
    var story: StoryProblem? = nil
}

enum StoryGames {
    static func make(_ kind: GameKind, age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        switch kind {
        case .timesGroups: return timesGroups(age: age, difficulty: difficulty)
        case .fairShare: return fairShare(age: age, difficulty: difficulty)
        case .storyMatch: return storyMatch(age: age, difficulty: difficulty)
        default: return timesGroups(age: age, difficulty: difficulty)  // never routed here; safe fallback
        }
    }

    private static func timesGroups(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let groupRange: ClosedRange<Int>
        let itemRange: ClosedRange<Int>
        switch difficulty {
        case .warmup:
            groupRange = 2...3
            itemRange = 2...3
        case .normal:
            groupRange = 2...5
            itemRange = 2...(age >= 9 ? 6 : 4)
        case .harder:
            groupRange = 3...5
            itemRange = 3...6
        case .challenge:
            groupRange = age >= 9 ? 6...10 : 3...5
            itemRange = age >= 9 ? 2...5 : 3...6
        }
        let picture = StoryGroupsPicture(groups: Int.random(in: groupRange),
                                         itemsPerGroup: Int.random(in: itemRange), item: "🍎",
                                         showsCalculation: age >= 9 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue)
        let choices = numberChoices(answer: picture.total, range: 1...(age >= 9 ? 50 : 30),
                                    candidates: [picture.groups + picture.itemsPerGroup,
                                                 picture.total - picture.itemsPerGroup,
                                                 picture.total + picture.itemsPerGroup])
        return exercise(.timesGroups,
                        prompt: L.t("How many apples in all?", no: "Hvor mange epler til sammen?",
                                    es: "¿Cuántas manzanas hay en total?", pt: "Quantas maçãs há ao todo?"),
                        picture: .groups(picture), choices: choices, answer: picture.total, difficulty: difficulty)
    }

    private static func fairShare(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let harder = difficulty.rawValue >= ExerciseDifficulty.harder.rawValue
        let friends = Int.random(in: 2...(difficulty == .warmup ? 3 : 5))
        let each = Int.random(in: 2...(difficulty == .warmup ? 4 : (age >= 10 && difficulty == .challenge ? 8 : 6)))
        let remainder = harder ? Int.random(in: 1..<friends) : 0
        let picture = StorySharingPicture(total: friends * each + remainder, friends: friends,
                                          item: "🍪", asksForRemainder: harder)
        let answer = harder ? remainder : each
        let choices = numberChoices(answer: answer, range: harder ? 0...(friends - 1) : 1...10,
                                    candidates: [each, friends, answer - 1, answer + 1])
        let prompt = harder
            ? L.t("Share fairly. How many are left over?", no: "Del likt. Hvor mange blir til overs?",
                  es: "Reparte por igual. ¿Cuántas sobran?", pt: "Divide igualmente. Quantas sobram?")
            : L.t("Share fairly. How many does each friend get?", no: "Del likt. Hvor mange får hver venn?",
                  es: "Reparte por igual. ¿Cuántas recibe cada amigo?", pt: "Divide igualmente. Quantas recebe cada amigo?")
        return exercise(.fairShare, prompt: prompt, picture: .sharing(picture), choices: choices,
                        answer: answer, difficulty: difficulty)
    }

    private static func storyMatch(age: Int, difficulty: ExerciseDifficulty) -> Exercise {
        let context = StoryContext.allCases.randomElement()!
        let story = StoryProblem(context: context, groups: context == .fairyTale ? 3 : Int.random(in: 3...5),
                                 itemsPerGroup: Int.random(in: 2...(difficulty == .warmup ? 3 : (age >= 10 ? 6 : 5))),
                                 operation: difficulty == .warmup || Bool.random() ? .times : .share)
        let picture: StoryPicture = story.operation == .times
            ? .groups(StoryGroupsPicture(groups: story.groups, itemsPerGroup: story.itemsPerGroup,
                                          item: story.item, character: story.character))
            : .sharing(StorySharingPicture(total: story.total, friends: story.groups,
                                            item: story.item, character: story.character))
        let choices = story.calculations.map { GameChoice(label: $0.label, value: $0.operation.rawValue) }.shuffled()
        return exercise(.storyMatch, prompt: story.prompt, picture: picture, choices: choices,
                        answer: story.operation.rawValue, difficulty: difficulty, story: story)
    }

    private static func numberChoices(answer: Int, range: ClosedRange<Int>, candidates: [Int]) -> [GameChoice] {
        var values = [answer]
        for value in candidates.shuffled() + Array(range).shuffled() where range.contains(value) && !values.contains(value) {
            values.append(value)
            if values.count == min(4, range.count) { break }
        }
        return values.shuffled().map { GameChoice(label: String($0), value: $0) }
    }

    private static func exercise(_ kind: GameKind, prompt: String, picture: StoryPicture, choices: [GameChoice],
                                 answer: Int, difficulty: ExerciseDifficulty, story: StoryProblem? = nil) -> Exercise {
        let operation: MathOperation
        switch picture {
        case .groups: operation = .multiplication
        case .sharing: operation = .division
        }
        return Exercise(game: GameSpec(kind: kind, prompt: prompt,
                                answerText: choices.first { $0.value == answer }!.label,
                                payload: StoryPayload(picture: picture, choices: choices, story: story)),
                        correctAnswer: answer, options: choices.map(\.value), difficulty: difficulty, operation: operation)
    }
}
