import Foundation
import Testing
@testable import Geni

@Suite("Calendar games", .serialized)
struct CalendarTests {
    private static let kinds: [GameKind] = [.weekdays, .seasons, .units, .shapes3D]
    private static let difficulties: [ExerciseDifficulty] = [.warmup, .normal, .harder, .challenge]
    private static let languageKey = "geni_app_language"

    /// Runs `body` once per app language, then puts the stored language back.
    private func eachLanguage(_ body: (AppLanguage) -> Void) {
        let stored = UserDefaults.standard.string(forKey: Self.languageKey)
        defer {
            if let stored { UserDefaults.standard.set(stored, forKey: Self.languageKey) } else {
                UserDefaults.standard.removeObject(forKey: Self.languageKey)
            }
        }
        for language in AppLanguage.allCases {
            L.selectedLanguage = language
            body(language)
        }
    }

    private func payload(_ exercise: Exercise) -> CalendarPayload {
        guard let payload = exercise.game?.payload as? CalendarPayload else {
            Issue.record("Calendar games carry a CalendarPayload")
            return CalendarPayload(scene: .emoji("?"), style: .text, choices: [], fact: .name(.cube))
        }
        return payload
    }

    @Test("Every kind, age and difficulty builds a well-formed game")
    func wellFormed() {
        eachLanguage { language in
            for kind in Self.kinds {
                for age in kind.ages {
                    for difficulty in Self.difficulties {
                        for _ in 0..<100 {
                            let exercise = GameFactory.make(kind, age: age, difficulty: difficulty)
                            let game = exercise.game
                            #expect(exercise.format == .game)
                            #expect(game?.kind == kind)
                            #expect(game?.prompt.isEmpty == false, "\(kind) \(language)")
                            #expect(game?.answerText.isEmpty == false, "\(kind) \(language)")
                            #expect(exercise.options.count >= 2 && exercise.options.count <= 4)
                            #expect(Set(exercise.options).count == exercise.options.count)
                            #expect(exercise.options.contains(exercise.correctAnswer))
                            #expect(exercise.options.allSatisfy { $0 >= 0 && $0 <= 16 })
                            if age <= 5 {
                                #expect(!(game?.prompt ?? "").contains(where: { "+=−×÷".contains($0) }))
                            }
                            let labels = payload(exercise).choices.map(\.label)
                            #expect(Set(labels).count == labels.count, "labels distinct \(kind) \(language) \(labels)")
                            #expect(labels.allSatisfy { !$0.isEmpty })
                        }
                    }
                }
            }
        }
    }

    // MARK: Weekdays

    @Test("Weekdays: the answer follows from the question and the row has one gap")
    func weekdays() {
        eachLanguage { language in
            let calendar = CalendarGames.weekCalendar()
            let short = CalendarGames.shortWeekdayNames()
            #expect(Set(short).count == 7, "short names distinct \(language)")
            for age in GameKind.weekdays.ages {
                for difficulty in Self.difficulties {
                    for _ in 0..<100 {
                        let p = payload(CalendarGames.make(.weekdays, age: age, difficulty: difficulty))
                        guard case let .weekday(relation, anchors, answer) = p.fact, case let .week(cells) = p.scene else {
                            Issue.record("weekday fact and week scene")
                            continue
                        }
                        let expected: Int
                        switch relation {
                        case .after: expected = (anchors[0] + 1) % 7
                        case .before: expected = (anchors[0] + 6) % 7
                        case .between: expected = (anchors[0] + 1) % 7
                            #expect((anchors[1] + 6) % 7 == expected)
                        case .twoAfter: expected = (anchors[0] + 2) % 7
                        case .twoBefore: expected = (anchors[0] + 5) % 7
                        }
                        #expect(answer == expected)
                        #expect(!anchors.contains(answer))
                        #expect(cells.count == 7)
                        #expect(cells.filter { $0.state == .missing }.count == 1)
                        #expect(cells.filter { $0.state == .anchor }.count == anchors.count)
                        if age <= 6 { #expect(relation == .after || relation == .before) }
                        // The row starts on the locale's first weekday.
                        let first = (calendar.firstWeekday - 1) % 7
                        if cells[0].state != .blank && cells[0].state != .missing { #expect(cells[0].label == short[first]) }
                        // Tiles are day names; the right tile is the day that fits.
                        #expect(p.choices.first { $0.value == answer }?.label == short[answer])
                        if difficulty == .warmup { #expect(cells.filter { $0.state == .blank }.isEmpty) }
                        if age >= 7 && difficulty.rawValue >= ExerciseDifficulty.harder.rawValue { #expect(!cells.filter { $0.state == .blank }.isEmpty) }
                    }
                }
            }
        }
    }

    @Test("Weekday names follow the language's locale")
    func weekdayLocale() {
        let stored = UserDefaults.standard.string(forKey: Self.languageKey)
        defer {
            if let stored { UserDefaults.standard.set(stored, forKey: Self.languageKey) } else {
                UserDefaults.standard.removeObject(forKey: Self.languageKey)
            }
        }
        L.selectedLanguage = .english
        #expect(CalendarGames.fullWeekdayNames()[1] == "Monday")
        #expect(CalendarGames.weekCalendar().firstWeekday == 1)
        L.selectedLanguage = .norwegian
        #expect(CalendarGames.fullWeekdayNames()[1] == "mandag")
        #expect(CalendarGames.weekCalendar().firstWeekday == 2)
        L.selectedLanguage = .spanish
        #expect(CalendarGames.fullWeekdayNames()[1] == "lunes")
        L.selectedLanguage = .portuguese
        #expect(CalendarGames.fullWeekdayNames()[1] == "segunda-feira")
    }

    // MARK: Seasons

    @Test("Seasons: each month maps to its season, flipped in the south")
    func seasonMapping() {
        let north = [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 0]   // Jan…Dec
        for month in 1...12 {
            #expect(CalendarGames.season(month: month, southern: false) == north[month - 1])
            #expect(CalendarGames.season(month: month, southern: true) == north[(month + 5) % 12])
        }
        #expect(CalendarGames.season(month: 12, southern: true) == 2)   // December: summer in Brazil
        #expect(CalendarGames.season(month: 7, southern: true) == 0)
    }

    @Test("Seasons: the right picture is the month's season in both hemispheres")
    func seasons() {
        eachLanguage { language in
            for southern in [false, true] {
                for age in GameKind.seasons.ages {
                    for difficulty in Self.difficulties {
                        for _ in 0..<100 {
                            let exercise = CalendarGames.makeSeasons(difficulty: difficulty, southern: southern)
                            let p = payload(exercise)
                            guard case let .season(month, flipped, answer) = p.fact, case let .month(name) = p.scene else {
                                Issue.record("season fact and month scene")
                                continue
                            }
                            _ = age
                            #expect(flipped == southern)
                            #expect(answer == CalendarGames.season(month: month, southern: southern))
                            #expect(exercise.correctAnswer == answer)
                            #expect(!name.isEmpty)
                            #expect(exercise.game?.prompt.localizedCaseInsensitiveContains(name) == true, "\(language)")
                            #expect(p.choices.first { $0.value == answer }?.label == CalendarGames.seasonPictures[answer])
                            #expect(p.choices.allSatisfy { CalendarGames.seasonPictures.contains($0.label) })
                            if difficulty == .warmup { #expect([1, 4, 7, 10].contains(month)) }
                        }
                    }
                }
            }
        }
    }

    // MARK: Units

    @Test("Units: the answer is the unit for the thing, in the region's system")
    func units() {
        for imperial in [false, true] {
            let allowed = imperial ? MeasureUnit.imperial : MeasureUnit.metric
            for difficulty in Self.difficulties {
                for _ in 0..<200 {
                    let exercise = CalendarGames.makeUnits(difficulty: difficulty, imperial: imperial)
                    let p = payload(exercise)
                    guard case let .unit(subject, flag, answer) = p.fact else {
                        Issue.record("unit fact")
                        continue
                    }
                    #expect(flag == imperial)
                    #expect(answer == subject.unit(imperial: imperial))
                    #expect(exercise.correctAnswer == answer.rawValue)
                    let units = p.choices.compactMap { MeasureUnit(rawValue: $0.value) }
                    #expect(units.count == p.choices.count)
                    #expect(units.allSatisfy { allowed.contains($0) })
                    // Every wrong tile is clearly wrong: another family, or far off in this one.
                    let far = subject.farUnits(imperial: imperial)
                    for unit in units where unit != answer {
                        #expect(unit.category != answer.category || far.contains(unit), "\(subject) \(unit)")
                    }
                }
            }
        }
    }

    @Test("Units: reference facts for each thing")
    func unitFacts() {
        #expect(UnitSubject.ant.unit(imperial: false) == .mm)
        #expect(UnitSubject.pencil.unit(imperial: false) == .cm)
        #expect(UnitSubject.bus.unit(imperial: false) == .m)
        #expect(UnitSubject.run.unit(imperial: false) == .km)
        #expect(UnitSubject.apple.unit(imperial: false) == .g)
        #expect(UnitSubject.elephant.unit(imperial: false) == .kg)
        #expect(UnitSubject.milk.unit(imperial: false) == .ml)
        #expect(UnitSubject.bath.unit(imperial: false) == .l)
        #expect(UnitSubject.pencil.unit(imperial: true) == .inch)
        #expect(UnitSubject.bus.unit(imperial: true) == .ft)
        #expect(UnitSubject.run.unit(imperial: true) == .mi)
        #expect(UnitSubject.apple.unit(imperial: true) == .oz)
        #expect(UnitSubject.elephant.unit(imperial: true) == .lb)
        #expect(UnitSubject.milk.unit(imperial: true) == .cup)
        #expect(UnitSubject.bath.unit(imperial: true) == .gal)
        for subject in UnitSubject.allCases {
            for imperial in [false, true] {
                #expect(!subject.farUnits(imperial: imperial).contains(subject.unit(imperial: imperial)))
            }
        }
    }

    // MARK: 3D shapes

    @Test("3D shapes: reference solid facts")
    func solidFacts() {
        #expect(Solid.cube.corners == 8 && Solid.cube.faces == 6 && Solid.cube.edges == 12)
        #expect(Solid.pyramid.corners == 5 && Solid.pyramid.faces == 5 && Solid.pyramid.edges == 8)
        #expect(Solid.cone.corners == 1 && Solid.cone.faces == 1)
        #expect(Solid.cylinder.corners == 0 && Solid.cylinder.faces == 2)
        #expect(Solid.sphere.corners == 0 && Solid.sphere.faces == 0)
        // Euler: corners − edges + faces = 2 for the flat-sided solids.
        for solid in [Solid.cube, .pyramid] { #expect(solid.corners - solid.edges! + solid.faces == 2) }
    }

    @Test("3D shapes: every question's answer is true")
    func shapes() {
        eachLanguage { language in
            for age in GameKind.shapes3D.ages {
                for difficulty in Self.difficulties {
                    for _ in 0..<150 {
                        let exercise = CalendarGames.make(.shapes3D, age: age, difficulty: difficulty)
                        let p = payload(exercise)
                        switch p.fact {
                        case let .count(property, solid, answer):
                            #expect(answer == CalendarGames.count(property, of: solid))
                            #expect(exercise.correctAnswer == answer)
                            if property == .edges { #expect(solid.isFlatSided) }
                            if property == .flatFaces { #expect(!solid.isFlatSided) }
                            if property == .faces { #expect(solid.isFlatSided) }
                            #expect(p.choices.count >= 3)
                        case let .rolls(answer):
                            #expect(answer == .sphere || answer == .cylinder)
                            #expect(exercise.correctAnswer == answer.rawValue)
                            let others = p.choices.compactMap { Solid(rawValue: $0.value) }.filter { $0 != answer }
                            #expect(others.allSatisfy { $0.isFlatSided })
                            #expect(p.style == .solids)
                        case let .name(solid):
                            #expect(exercise.correctAnswer == solid.rawValue)
                            #expect(p.choices.first { $0.value == solid.rawValue }?.label == solid.name)
                        default:
                            Issue.record("unexpected fact for shapes3D \(language)")
                        }
                    }
                }
            }
        }
    }

    @Test("Solid names and prompts exist in every language")
    func languages() {
        eachLanguage { language in
            for solid in Solid.allCases {
                #expect(!solid.name.isEmpty && !solid.withArticle.isEmpty, "\(language)")
                for property in [SolidProperty.corners, .faces, .edges, .flatFaces] {
                    #expect(!CalendarGames.countPrompt(property, solid).isEmpty)
                }
            }
            for subject in UnitSubject.allCases { #expect(!subject.prompt.isEmpty) }
            for unit in MeasureUnit.allCases { #expect(!unit.label.isEmpty) }
            for relation in WeekRelation.allCases {
                #expect(!CalendarGames.weekdayPrompt(relation, names: ["a", "b"]).isEmpty)
            }
        }
    }
}
