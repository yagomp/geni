import XCTest

/// End-to-end flows. The app is launched with `-uiTest -uiTestReset` (DEBUG hooks in UITestSupport.swift):
/// state is wiped on every launch and a hidden `ui.state` element exposes the view model state.
final class GeniEndToEndTests: XCTestCase {
    private var app: XCUIApplication!
    private let shotDir = "/tmp/geni-e2e"
    private var matchExercisesSeen = 0
    private var wrongMatchConnections = 0

    override func setUpWithError() throws {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(atPath: shotDir, withIntermediateDirectories: true)
        app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-uiTestReset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    // MARK: - Helpers

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func state() -> [String: String] {
        let el = element("ui.state")
        guard el.exists, let value = el.value as? String else { return [:] }
        var result: [String: String] = [:]
        for part in value.components(separatedBy: "|") {
            guard let eq = part.firstIndex(of: "=") else { continue }
            result[String(part[..<eq])] = String(part[part.index(after: eq)...])
        }
        return result
    }

    @discardableResult
    private func waitFor(_ timeout: TimeInterval = 10, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return condition()
    }

    private func waitScreen(_ screen: String, timeout: TimeInterval = 15, file: StaticString = #filePath, line: UInt = #line) {
        let ok = waitFor(timeout) { state()["screen"] == screen }
        XCTAssertTrue(ok, "expected screen \(screen), state: \(state())", file: file, line: line)
    }

    private func tap(_ id: String, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let el = element(id)
        let ok = waitFor(timeout) { el.exists && el.isHittable }
        XCTAssertTrue(ok, "\(id) not tappable. state: \(state())", file: file, line: line)
        el.tap()
    }

    private func screenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(shotDir)/\(name).png"))
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func scrollUntilHittable(_ el: XCUIElement) {
        var tries = 0
        while !(el.exists && el.isHittable) && tries < 6 && app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeUp()
            tries += 1
        }
    }

    private func coins() -> Int { Int(state()["coins"] ?? "") ?? -1 }

    private func coins(of name: String) -> Int? {
        guard let by = state()["coinsBy"] else { return nil }
        for pair in by.components(separatedBy: ",") {
            let kv = pair.components(separatedBy: ":")
            if kv.count == 2, kv[0] == name { return Int(kv[1]) }
        }
        return nil
    }

    private func dismissCelebrations(settle: TimeInterval = 1.5) {
        var idle = 0
        while idle < 3 {
            let level = element("levelUp.dismiss")
            let badge = element("badge.dismiss")
            if level.exists && level.isHittable {
                level.tap(); idle = 0
            } else if badge.exists && badge.isHittable {
                badge.tap(); idle = 0
            } else {
                Thread.sleep(forTimeInterval: settle / 3)
                idle += 1
            }
        }
    }

    // MARK: Profile form

    /// Creation is three steps (avatar → name + age → colours + corners); editing is one scrolling form.
    /// `ops` only applies to the edit form; creation keeps the age's recommended operations.
    private func fillProfileForm(name: String? = nil, age: Int? = nil, avatar: String? = nil,
                                 theme: String? = nil, ops: Set<String>? = nil) {
        let nameField = app.textFields["profile.name"]
        XCTAssertTrue(waitFor { self.element("profile.step.1").exists || nameField.exists }, "profile form missing. state: \(state())")
        if element("profile.step.1").exists {
            fillCreationSteps(name: name, age: age, avatar: avatar, theme: theme)
            return
        }
        if let name {
            typeName(name, into: nameField)
        }
        if let age {
            let b = element("profile.age.\(age)")
            scrollUntilHittable(b)
            b.tap()
        }
        if let avatar {
            chooseAvatarInSheet(avatar)
        }
        if let theme {
            let b = element("profile.theme.\(theme)")
            scrollUntilHittable(b)
            b.tap()
        }
        if let ops {
            setOps(ops)
        }
    }

    private func fillCreationSteps(name: String?, age: Int?, avatar: String?, theme: String?) {
        // Step 1: avatar
        if let avatar {
            // All avatars are shown directly in creation step 1
            let tile = element("profile.avatar.\(avatar)")
            XCTAssertTrue(tile.waitForExistence(timeout: 5), "avatar \(avatar) missing in step 1")
            scrollUntilHittable(tile)
            tile.tap()
            XCTAssertTrue(waitFor(2) { tile.isSelected }, "avatar \(avatar) not selected")
        }
        tap("profile.next")

        // Step 2: age, then name; Return advances when the name is valid
        XCTAssertTrue(element("profile.step.2").waitForExistence(timeout: 5), "step 2 missing. state: \(state())")
        if let age {
            tap("profile.age.\(age)")
            XCTAssertTrue(waitFor(2) { self.element("profile.age.\(age)").isSelected }, "age \(age) not selected")
        }
        let nameField = app.textFields["profile.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        if let name {
            typeName(name, into: nameField)
        } else {
            tap("profile.next")
        }

        // Step 3: colours, corners
        XCTAssertTrue(element("profile.step.3").waitForExistence(timeout: 5), "Return did not reach step 3. state: \(state())")
        if let theme {
            tap("profile.theme.\(theme)")
            XCTAssertTrue(waitFor(2) { self.element("profile.theme.\(theme)").isSelected }, "theme \(theme) not selected")
        }
    }

    private func typeName(_ name: String, into nameField: XCUIElement) {
        nameField.tap()
        if let current = nameField.value as? String, !current.isEmpty, current != nameField.placeholderValue {
            nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        nameField.typeText(name + "\n")
    }

    /// Opens the full chooser, picks `avatar` (the sheet stays open on tap) and closes it with ✓.
    private func chooseAvatarInSheet(_ avatar: String) {
        let more = element("profile.avatar.more")
        scrollUntilHittable(more)
        more.tap()
        XCTAssertTrue(element("avatar.sheet.done").waitForExistence(timeout: 5), "avatar chooser did not open")
        let tile = element("profile.avatar.\(avatar)")
        XCTAssertTrue(waitFor { tile.exists && tile.isHittable }, "avatar \(avatar) not in chooser")
        tile.tap()
        XCTAssertTrue(element("avatar.sheet.done").exists, "chooser closed on tap")
        tap("avatar.sheet.done")
        XCTAssertTrue(waitFor(5) { !self.element("avatar.sheet.done").exists }, "avatar chooser did not close")
    }

    private func setOps(_ ops: Set<String>) {
        let all = ["addition", "subtraction", "multiplication", "division"]
        // add first so the last remaining operation is never removed
        for op in all where ops.contains(op) && !element("profile.op.\(op)").isSelected {
            let b = element("profile.op.\(op)"); scrollUntilHittable(b); b.tap()
        }
        for op in all where !ops.contains(op) && element("profile.op.\(op)").isSelected {
            let b = element("profile.op.\(op)"); scrollUntilHittable(b); b.tap()
        }
    }

    /// From the parent dashboard: opens `name`'s edit form, applies `ops` and saves back to the list.
    private func setOpsViaParentEdit(name: String, ops: Set<String>) {
        tap("parent.edit.\(name)")
        XCTAssertTrue(element("profile.op.addition").waitForExistence(timeout: 5), "edit form missing. state: \(state())")
        setOps(ops)
        XCTAssertEqual(selectedOps(), ops, "operations not applied in edit form")
        tap("profile.save")
        XCTAssertTrue(element("parent.edit.\(name)").waitForExistence(timeout: 10), "\(name) missing after saving operations")
    }

    private func selectedOps() -> Set<String> {
        Set(["addition", "subtraction", "multiplication", "division"].filter {
            let b = element("profile.op.\($0)"); scrollUntilHittable(b); return b.isSelected
        })
    }

    private func createFirstProfile(name: String, age: Int? = nil, avatar: String? = nil,
                                    theme: String? = nil, ops: Set<String>? = nil) {
        tap("welcome.start")
        fillProfileForm(name: name, age: age, avatar: avatar, theme: theme)
        tap("profile.save")
        waitScreen("childHome")
        if let ops {
            tap("home.settings")
            XCTAssertTrue(element("parent.title").waitForExistence(timeout: 10))
            setOpsViaParentEdit(name: name, ops: ops)
            tap("parent.back")
            waitScreen("childHome")
        }
    }

    private func addProfileFromParentDashboard(name: String, age: Int? = nil, avatar: String? = nil,
                                               theme: String? = nil, ops: Set<String>? = nil) {
        tap("home.settings")
        XCTAssertTrue(element("parent.title").waitForExistence(timeout: 10))
        tap("parent.add")
        fillProfileForm(name: name, age: age, avatar: avatar, theme: theme)
        tap("profile.save")
        XCTAssertTrue(element("parent.edit.\(name)").waitForExistence(timeout: 10), "new profile \(name) missing in parent list")
        if let ops {
            setOpsViaParentEdit(name: name, ops: ops)
        }
        tap("parent.back")
        waitScreen("childHome")
    }

    // MARK: Math chapter

    /// Answers the 20 exercises. Every 5th exercise (index % 5 == 2) is answered wrong once first,
    /// index 4 twice (the "show answer" path), and the first matching exercise gets a wrong connection.
    /// `stopAfter` leaves the exercise screen once that many exercises are saved (via the back button).
    private func playChapter(stopAfter: Int? = nil, leaveDuringFinalFeedback: Bool = false) {
        var lastKey = ""
        var lastKeyAt = Date()
        var guardCount = 0
        var firstMatchWrongDone = false
        while guardCount < 3000 {
            guardCount += 1
            let s = state()
            if s["screen"] != "exercise" { return }
            guard let ex = s["ex"] else { Thread.sleep(forTimeInterval: 0.2); continue }
            let p = ex.components(separatedBy: ";")
            guard p.count == 4, p[3] == "ready", p[1] != "done" else { Thread.sleep(forTimeInterval: 0.2); continue }
            let idx = Int(p[0])!
            let format = p[1]
            let target = p[2]
            let key = "\(idx);\(target)"
            if key == lastKey {
                // The simulator is shared; if another process pulled the app to the background, bring it back
                if app.state != .runningForeground { print("CHAPTER-LOOP: app not foreground (\(app.state.rawValue)), activating"); app.activate() }
                if Date().timeIntervalSince(lastKeyAt) > 8 {
                    print("CHAPTER-LOOP: stuck on \(key) for 8s, retrying; state \(s)")
                    screenshot("stuck-\(idx)")
                    lastKey = ""
                } else {
                    Thread.sleep(forTimeInterval: 0.2)
                    continue
                }
            }

            if let stopAfter, idx >= stopAfter {
                tap("exercise.back")
                return
            }
            lastKey = key
            lastKeyAt = Date()

            if format == "matchConnect" || format == "clockMatch" {
                matchExercisesSeen += 1
                let correct = target.components(separatedBy: ",").map { Int($0)! }
                if !firstMatchWrongDone {
                    firstMatchWrongDone = true
                    wrongMatchConnections += 1
                    connect(left: 0, right: (correct[0] + 1) % correct.count, viaDrag: true)
                    Thread.sleep(forTimeInterval: 0.8)
                }
                for (l, r) in correct.enumerated() { connect(left: l, right: r, viaDrag: l == correct.count - 1) }
            } else if format == "clockSet" {
                setClock(totalMinutes: Int(target) ?? 0)
                tap("clock.check")
            } else {
                let wrongTaps = idx == 4 ? 2 : (idx % 5 == 2 ? 1 : 0)
                var wrongDone = 0
                for _ in 0..<wrongTaps {
                    guard tapWrongAnswer(target: target) else { break }
                    wrongDone += 1
                    _ = waitFor(5) { state()["ex"]?.hasSuffix("ready") == true || state()["screen"] != "exercise" }
                }
                // two wrong taps end the exercise ("show answer"), so there is nothing left to tap
                if wrongDone < 2 {
                    tap("answer.\(target)")
                }
            }

            if leaveDuringFinalFeedback && idx == 19 {
                tap("exercise.back")
                return
            }
            Thread.sleep(forTimeInterval: 0.3)
        }
        XCTFail("chapter loop did not finish; state: \(state())")
    }

    @discardableResult
    private func tapWrongAnswer(target: String) -> Bool {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'answer.' AND identifier != %@", "answer.\(target)")
        let wrong = app.buttons.matching(predicate).firstMatch
        guard wrong.waitForExistence(timeout: 3), wrong.isHittable else { return false }
        wrong.tap()
        return true
    }

    /// Sets the analog clock face to `totalMinutes` (minutes past 12:00) by dragging the minute, then the hour handle.
    private func setClock(totalMinutes t: Int) {
        let minute = t % 60
        let faceQuery = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == 'Set the clock' AND elementType != %d", XCUIElement.ElementType.staticText.rawValue))
        let face = faceQuery.firstMatch
        XCTAssertTrue(face.waitForExistence(timeout: 5), "clock face missing. state: \(state())")
        func point(angle: Double, fraction: Double) -> XCUICoordinate {
            let r = angle * .pi / 180
            return face.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + fraction * 0.5 * sin(r), dy: 0.5 - fraction * 0.5 * cos(r)))
        }
        let minuteHand = element("clock.minuteHand")
        if minuteHand.exists {
            minuteHand.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: point(angle: Double(minute) * 6, fraction: 0.85))
            Thread.sleep(forTimeInterval: 0.3)
        }
        let hourHand = element("clock.hourHand")
        XCTAssertTrue(hourHand.waitForExistence(timeout: 5), "hour handle missing")
        hourHand.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: point(angle: Double(t % 720) * 0.5, fraction: 0.5))
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// Connects a pair: by dragging a line when `viaDrag`, otherwise tapping the card then its partner.
    private func connect(left: Int, right: Int, viaDrag: Bool = false) {
        let l = element("match.left.\(left)")
        let r = element("match.right.\(right)")
        XCTAssertTrue(l.waitForExistence(timeout: 5) && r.waitForExistence(timeout: 5), "match cards missing")
        if viaDrag {
            l.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: r.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        } else {
            l.tap()
            r.tap()
        }
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// Starts today's chapter from home and plays it through to the first completion screen.
    private func finishTodaysChapter(file: StaticString = #filePath, line: UInt = #line) {
        tap("home.mission")
        waitScreen("exercise")
        playChapter()
        XCTAssertTrue(waitFor(20) {
            ["chapterComplete", "missionTransition"].contains(state()["screen"] ?? "")
        }, "chapter did not complete; state: \(state())", file: file, line: line)
    }

    // MARK: - A. Profile switching (original complaint)

    func testA_ProfileSwitching() {
        createFirstProfile(name: "Ada", age: 6, avatar: "lion")
        XCTAssertEqual(element("home.name").label, "Ada")
        screenshot("01-home-single-profile")

        // With one profile the avatar opens the avatar chooser, not the profile picker.
        // A tap selects and keeps it open; ✓ closes it.
        tap("home.avatar")
        XCTAssertTrue(element("avatar.sheet.done").waitForExistence(timeout: 5), "avatar chooser did not open")
        XCTAssertEqual(state()["screen"], "childHome")
        tap("avatar.unicorn")
        XCTAssertTrue(waitFor(2) { self.element("avatar.unicorn").isSelected }, "chooser tap did not select")
        XCTAssertTrue(element("avatar.sheet.done").exists, "chooser closed on tap")
        screenshot("01b-avatar-chooser")
        tap("avatar.sheet.done")
        XCTAssertTrue(waitFor(5) { !self.element("avatar.sheet.done").exists }, "avatar chooser did not close")
        XCTAssertEqual(state()["screen"], "childHome")

        addProfileFromParentDashboard(name: "Bo", age: 8, avatar: "robot", theme: "ocean", ops: ["addition", "division"])
        XCTAssertTrue(element("home.sibling.Bo").waitForExistence(timeout: 5))
        XCTAssertEqual(state()["theme"], "standard")
        screenshot("02-home-multiple-profiles")

        // Main avatar -> profile picker -> pick Bo
        tap("home.avatar")
        waitScreen("profilePicker")
        XCTAssertTrue(element("picker.profile.Ada").exists && element("picker.profile.Bo").exists)
        screenshot("03-profile-picker")
        tap("picker.profile.Bo")
        waitScreen("childHome")
        XCTAssertEqual(state()["active"], "Bo")
        XCTAssertEqual(state()["theme"], "ocean")
        XCTAssertEqual(element("home.name").label, "Bo")
        XCTAssertTrue(element("home.sibling.Ada").exists)
        screenshot("04-after-switch-to-bo")

        // Sibling avatar button switches back
        tap("home.sibling.Ada")
        XCTAssertTrue(waitFor { state()["active"] == "Ada" })
        XCTAssertEqual(state()["theme"], "standard")
        XCTAssertEqual(element("home.name").label, "Ada")

        // Add a profile from the picker
        tap("home.avatar")
        waitScreen("profilePicker")
        tap("picker.add")
        fillProfileForm(name: "Cy", age: 7, avatar: "rocket")
        screenshot("05-add-profile-from-picker")
        tap("profile.save")
        XCTAssertTrue(element("picker.profile.Cy").waitForExistence(timeout: 10), "Cy missing in picker. state: \(state())")
        XCTAssertEqual(state()["profiles"], "Ada,Bo,Cy")
        tap("picker.profile.Cy")
        waitScreen("childHome")
        XCTAssertEqual(state()["active"], "Cy")
        XCTAssertEqual(element("home.name").label, "Cy")
        XCTAssertTrue(element("home.sibling.Ada").exists && element("home.sibling.Bo").exists)
        screenshot("06-home-three-profiles")
    }

    // MARK: - Shared flow helpers

    private func relaunch() {
        app.terminate()
        app.launchArguments = ["-uiTest", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    private func clearName() {
        let field = app.textFields["profile.name"]
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
    }

    /// Leaves the post-math screen: age 6 gets the mission transition with an optional "Done"; younger kids the plain completion screen.
    private func leaveMathCompletion() {
        if state()["screen"] == "chapterComplete" {
            tap("chapterComplete.done")
        } else {
            tap("missionTransition.finish")
        }
        waitScreen("childHome")
    }

    private struct ReadingSnapshot {
        var index = 0, total = 0, matched = 0
        var playing = false, paused = false, done = false
        var error = ""
    }

    private func reading() -> ReadingSnapshot? {
        guard let rd = state()["rd"] else { return nil }
        let p = rd.split(separator: ",", maxSplits: 7, omittingEmptySubsequences: false).map(String.init)
        guard p.count == 8 else { return nil }
        func flag(_ s: String) -> Bool { s.hasSuffix(":true") }
        return ReadingSnapshot(index: Int(p[1]) ?? 0, total: Int(p[2]) ?? 0, matched: Int(p[6].split(separator: ":").last ?? "0") ?? 0,
                               playing: flag(p[3]), paused: flag(p[4]), done: flag(p[5]),
                               error: p[7].hasPrefix("err:") ? String(p[7].dropFirst(4)) : p[7])
    }

    /// "Read to me": highlighting progresses, pause holds it, resume continues, then the reading completes.
    /// Returns true if it finished on its own (false: the finish button was needed).
    @discardableResult
    private func playReadToMe(screenshotPrefix: String, expectedNext: String) -> Bool {
        tap("readingMode.readToMe")
        waitScreen("reading")
        XCTAssertTrue(waitFor(15) { reading()?.playing == true }, "reading never started: \(state())")
        XCTAssertTrue(waitFor(40) { (reading()?.index ?? 0) >= 3 }, "highlight did not progress: \(String(describing: reading()))")
        screenshot("\(screenshotPrefix)-read-to-me-playing")

        tap("reading.playPause")
        XCTAssertTrue(waitFor(5) { reading()?.paused == true }, "pause not reflected: \(String(describing: reading()))")
        Thread.sleep(forTimeInterval: 1.0)
        let pausedAt = reading()?.index ?? -1
        Thread.sleep(forTimeInterval: 3.0)
        let stillAt = reading()?.index ?? -2
        XCTAssertLessThanOrEqual(stillAt - pausedAt, 1, "highlighting kept moving while paused (\(pausedAt) -> \(stillAt))")
        screenshot("\(screenshotPrefix)-read-to-me-paused")

        tap("reading.playPause")
        XCTAssertTrue(waitFor(5) { reading()?.playing == true }, "resume not reflected")
        XCTAssertTrue(waitFor(40) { (reading()?.index ?? 0) > pausedAt + 2 }, "highlight did not progress after resume (paused at \(pausedAt)): \(String(describing: reading()))")

        var natural = true
        let finished = waitFor(150) { state()["screen"] == expectedNext }
        if !finished {
            natural = false
            let finish = element("reading.finish")
            if finish.exists { finish.tap() }
            waitScreen(expectedNext, timeout: 10)
        }
        screenshot("\(screenshotPrefix)-reading-complete")
        return natural
    }

    // MARK: - B. Profile editing

    func testB_ProfileEditing() {
        createFirstProfile(name: "Ada", age: 6)
        addProfileFromParentDashboard(name: "Bo", age: 8, avatar: "robot", theme: "ocean", ops: ["addition", "division"])

        // Custom operations and age != 6 survive opening the editor (inactive child)
        tap("home.settings")
        tap("parent.edit.Bo")
        XCTAssertEqual(app.textFields["profile.name"].value as? String, "Bo")
        XCTAssertTrue(element("profile.age.8").isSelected, "age 8 not selected")
        XCTAssertEqual(selectedOps(), ["addition", "division"], "custom operations lost on open")
        XCTAssertTrue(element("profile.theme.ocean").isSelected)
        screenshot("10-edit-profile-bo")

        // Back with an empty name does not save an empty name
        clearName()
        tap("profile.back")
        XCTAssertTrue(element("parent.edit.Bo").waitForExistence(timeout: 10), "Bo disappeared after Back with empty name")
        XCTAssertFalse(element("parent.edit.").exists)
        tap("parent.edit.Bo")
        XCTAssertEqual(app.textFields["profile.name"].value as? String, "Bo", "name changed after empty Back")
        XCTAssertEqual(selectedOps(), ["addition", "division"], "operations changed after empty Back")

        // Back with a valid name saves (theme change on the inactive child)
        fillProfileForm(theme: "blossom")
        tap("profile.back")
        XCTAssertTrue(element("parent.edit.Bo").waitForExistence(timeout: 10))
        tap("parent.back")
        waitScreen("childHome")
        XCTAssertEqual(state()["active"], "Ada")
        XCTAssertEqual(state()["theme"], "standard", "editing inactive Bo changed the active child's theme")
        XCTAssertEqual(state()["profiles"], "Ada,Bo")

        // Saved edit persisted with ops intact
        tap("home.settings")
        tap("parent.edit.Bo")
        XCTAssertTrue(element("profile.theme.blossom").isSelected, "theme edit not saved")
        XCTAssertEqual(selectedOps(), ["addition", "division"], "operations lost after saving edit")
        XCTAssertTrue(element("profile.age.8").isSelected)
        screenshot("11-edit-profile-after-save")
        tap("profile.back")
        XCTAssertTrue(element("parent.edit.Bo").waitForExistence(timeout: 10))

        // Editing the active child does apply its theme
        tap("parent.edit.Ada")
        fillProfileForm(theme: "ocean")
        tap("profile.save")
        XCTAssertTrue(element("parent.edit.Ada").waitForExistence(timeout: 10))
        tap("parent.back")
        waitScreen("childHome")
        XCTAssertEqual(state()["theme"], "ocean")
    }

    // MARK: - C. Math chapter, optional reading (age 6), rewards, multi-child coins, delete active

    func testC_MathChapterRewardsAndDeleteActiveProfile() {
        createFirstProfile(name: "Ada", age: 6)
        XCTAssertEqual(coins(), 0)
        finishTodaysChapter()
        XCTAssertEqual(state()["screen"], "missionTransition", "age 6 math completion should show the mission transition")
        screenshot("20-chapter-complete-raw")
        let adaMathCoins = coins()
        XCTAssertGreaterThan(adaMathCoins, 0, "no coins awarded")
        dismissCelebrations()
        XCTAssertTrue(element("missionTransition.finish").exists && element("missionTransition.continue").exists)
        screenshot("21-chapter-complete")
        XCTAssertEqual(coins(), adaMathCoins, "coins changed while sitting on the completion screen")
        leaveMathCompletion()
        XCTAssertEqual(coins(), adaMathCoins)
        XCTAssertEqual(element("home.coins").label, "\(adaMathCoins)")
        screenshot("22-home-after-chapter")

        // Optional reading button still reachable after math
        let optional = element("home.optionalReading")
        XCTAssertTrue(optional.waitForExistence(timeout: 5) && optional.isHittable, "optional reading button missing for age 6")
        tap("home.optionalReading")
        waitScreen("readingMode")
        screenshot("23-reading-mode-selection")
        playReadToMe(screenshotPrefix: "24", expectedNext: "readingComplete")
        dismissCelebrations()
        tap("readingComplete.done")
        waitScreen("childHome")
        let adaCoins = coins()
        XCTAssertEqual(adaCoins, adaMathCoins + 30, "reading should award 15 + 15 daily bonus exactly once")

        // Rewards (badges) and parent dashboard open
        tap("home.rewards")
        XCTAssertTrue(element("rewards.title").waitForExistence(timeout: 10))
        screenshot("25-rewards-badges")
        tap("rewards.back")
        waitScreen("childHome")
        tap("home.settings")
        XCTAssertTrue(element("parent.title").waitForExistence(timeout: 10))
        screenshot("26-parent-dashboard")
        app.scrollViews.firstMatch.swipeUp()
        screenshot("27-parent-dashboard-scrolled")
        tap("parent.back")
        waitScreen("childHome")

        // Second child: switching changes the coins, then deleting the active child keeps Ada intact
        addProfileFromParentDashboard(name: "Bo", age: 6, avatar: "robot", theme: "ocean")
        tap("home.avatar")
        waitScreen("profilePicker")
        tap("picker.profile.Bo")
        waitScreen("childHome")
        XCTAssertEqual(state()["active"], "Bo")
        XCTAssertEqual(coins(), 0, "Bo should start with 0 coins")
        XCTAssertEqual(element("home.coins").label, "0")
        finishTodaysChapter()
        dismissCelebrations()
        let boCoins = coins()
        XCTAssertGreaterThan(boCoins, 0)
        XCTAssertEqual(coins(of: "Ada"), adaCoins, "Bo's chapter changed Ada's stored coins")
        leaveMathCompletion()
        tap("home.sibling.Ada")
        XCTAssertTrue(waitFor { state()["active"] == "Ada" })
        XCTAssertEqual(coins(), adaCoins, "switching back to Ada shows wrong coins")
        XCTAssertEqual(element("home.coins").label, "\(adaCoins)")
        tap("home.sibling.Bo")
        XCTAssertTrue(waitFor { state()["active"] == "Bo" })
        XCTAssertEqual(coins(), boCoins)

        // Delete the active child (Bo) in the parent dashboard
        tap("home.settings")
        tap("parent.delete.Bo")
        XCTAssertTrue(waitFor { !element("parent.delete.Bo").exists && !element("parent.edit.Bo").exists })
        screenshot("28-parent-after-delete-active")
        tap("parent.back")
        waitScreen("childHome")
        XCTAssertEqual(state()["profiles"], "Ada")
        XCTAssertEqual(state()["active"], "Ada")
        XCTAssertEqual(coins(), adaCoins, "remaining child's coins corrupted by deleting the active profile")
        XCTAssertEqual(coins(of: "Ada"), adaCoins)
        XCTAssertEqual(element("home.coins").label, "\(adaCoins)")
        // Leaving/entering screens must not write the deleted child's state over Ada
        tap("home.rewards")
        XCTAssertTrue(element("rewards.title").waitForExistence(timeout: 10))
        screenshot("29-rewards-after-delete")
        tap("rewards.back")
        waitScreen("childHome")
        relaunch()
        waitScreen("childHome")
        XCTAssertEqual(state()["active"], "Ada")
        XCTAssertEqual(coins(), adaCoins, "coins changed after relaunch")
    }

    // MARK: - D. Resume mid-chapter and resume after the last answer was saved

    func testD_ResumeMidChapterAndAfterFinalAnswer() {
        createFirstProfile(name: "Ada", age: 6)
        tap("home.mission")
        waitScreen("exercise")
        playChapter(stopAfter: 3)
        waitScreen("childHome")
        XCTAssertEqual(coins(), 0)
        XCTAssertTrue(element("home.mission").waitForExistence(timeout: 5))
        screenshot("30-home-mid-chapter")

        // Resume continues at exercise 4
        tap("home.mission")
        waitScreen("exercise")
        XCTAssertTrue(waitFor { element("exercise.counter").exists })
        XCTAssertTrue(element("exercise.counter").label.hasPrefix("4 "), "resume did not continue at exercise 4: \(element("exercise.counter").label)")
        screenshot("31-resumed-exercise-4")

        // Answer through the 20th exercise, then leave right after the final answer was saved
        playChapter(leaveDuringFinalFeedback: true)
        waitScreen("childHome")
        XCTAssertEqual(coins(), 0, "coins awarded before completion was shown")
        // Back out immediately: everything is saved but the completion screen was never reached
        tap("home.mission")
        XCTAssertTrue(waitFor(15) { ["chapterComplete", "missionTransition"].contains(state()["screen"] ?? "") }, "resume after final answer did not reach the completion screen: \(state())")
        XCTAssertTrue(element("chapterComplete.done").waitForExistence(timeout: 10) || element("missionTransition.finish").waitForExistence(timeout: 10), "completion screen is blank")
        screenshot("32-resume-after-final-answer-complete")
        let coinsAfter = coins()
        XCTAssertGreaterThan(coinsAfter, 0)
        dismissCelebrations()
        leaveMathCompletion()
        XCTAssertEqual(coins(), coinsAfter, "coins changed after leaving the completion screen")
        relaunch()
        waitScreen("childHome")
        XCTAssertEqual(coins(), coinsAfter, "coins awarded more than once")
        XCTAssertFalse(element("home.mission").exists, "chapter restartable after completion")
    }

    // MARK: - E0. Age 8: required reading mission flow

    func testE0_RequiredReadingMissionFlow() {
        createFirstProfile(name: "Bo", age: 8, avatar: "robot", theme: "ocean")
        finishTodaysChapter()
        XCTAssertEqual(state()["screen"], "missionTransition")
        screenshot("40-mission-transition-raw")
        let mathCoins = coins()
        XCTAssertGreaterThan(mathCoins, 0)
        dismissCelebrations()
        screenshot("41-mission-transition")
        tap("missionTransition.continue")
        waitScreen("readingMode")
        playReadToMe(screenshotPrefix: "42", expectedNext: "missionComplete")
        dismissCelebrations()
        screenshot("43-mission-complete")
        XCTAssertEqual(coins(), mathCoins + 30, "mission reading coins should be awarded exactly once")
        tap("missionComplete.done")
        waitScreen("childHome")
        XCTAssertEqual(coins(), mathCoins + 30)
        screenshot("44-home-mission-done")
        XCTAssertFalse(element("home.mission").exists, "mission button still offered after full mission")
        XCTAssertGreaterThan(matchExercisesSeen + 1, 0)
    }

    // MARK: - E. "Listen to me read" with the simulator's microphone/speech state

    func testE_ListenToMeRead() {
        createFirstProfile(name: "Ada", age: 6)
        finishTodaysChapter()
        dismissCelebrations()
        let before = coins()
        tap("missionTransition.continue")
        waitScreen("readingMode")
        tap("readingMode.listenToMe")
        waitScreen("reading")
        screenshot("50-listen-mode-start")

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        var outcome = "unknown"
        if alert.waitForExistence(timeout: 8) {
            outcome = "permission-prompt-pending"
            screenshot("51-listen-permission-prompt")
            // Leave the reading screen while the prompt is still up
            tap("reading.back")
            XCTAssertTrue(waitFor(5) { state()["screen"] == "childHome" }, "could not leave reading while prompt pending: \(state())")
            var answered = 0
            while answered < 3, springboard.alerts.firstMatch.waitForExistence(timeout: 4) {
                let a = springboard.alerts.firstMatch
                let allow = a.buttons.allElementsBoundByIndex.first { ["Allow", "OK", "Allow While Using App"].contains($0.label) }
                (allow ?? a.buttons.element(boundBy: a.buttons.count - 1)).tap()
                answered += 1
            }
            Thread.sleep(forTimeInterval: 4)
            XCTAssertEqual(state()["screen"], "childHome")
            XCTAssertNil(state()["rd"], "reading view model still alive after leaving")
            XCTAssertFalse(element("reading.feedback").exists)
            XCTAssertEqual(coins(), before)
            screenshot("52-after-leaving-with-prompt-pending")
        } else {
            _ = waitFor(15) { (reading()?.paused == true && !(reading()?.error.isEmpty ?? true)) }
            let r = reading()
            if let r, r.paused, !r.error.isEmpty {
                outcome = "error-paused"
                XCTAssertFalse(r.done)
                XCTAssertTrue(element("reading.feedback").exists, "no error banner shown")
                screenshot("53-listen-error-state")
                // Resume must not complete or award anything
                tap("reading.playPause")
                Thread.sleep(forTimeInterval: 4)
                XCTAssertEqual(state()["screen"], "reading")
                XCTAssertEqual(reading()?.done, false)
                XCTAssertEqual(coins(), before)
            } else {
                outcome = "listening(\(String(describing: r)))"
                Thread.sleep(forTimeInterval: 15)
                screenshot("54-listen-mode-listening")
                XCTAssertEqual(reading()?.done, false, "listen mode completed on its own within 15s")
                XCTAssertEqual(coins(), before)
            }
            tap("reading.back")
            waitScreen("childHome")
            XCTAssertEqual(coins(), before, "rewards awarded by leaving listen mode")
        }
        add(XCTAttachment(string: "listen outcome: \(outcome)"))
        print("LISTEN-OUTCOME: \(outcome)")
    }
}
