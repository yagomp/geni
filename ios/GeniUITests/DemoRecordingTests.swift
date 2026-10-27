#if DEBUG
import XCTest

/// Opt-in capture driver, excluded from normal UI runs. Set DEMO_RECORDING=1
/// in the test runner environment; DEMO_LANGUAGE=no selects Norwegian.
/// DEMO_CAPTURE=1 adds a file handshake in the runner's Documents directory so
/// simctl can begin/end one continuous recording while the app is visible.
final class DemoRecordingTests: XCTestCase {
    private var app: XCUIApplication!
    private var startedAt = Date()
    private let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    @MainActor
    func testWalkthrough() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DEMO_RECORDING"] == "1", "Opt-in demo recording")
        continueAfterFailure = false
        let norwegian = ProcessInfo.processInfo.environment["DEMO_LANGUAGE"] == "no"
        app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-demoRecording", "-demoGames",
                               "-geni_app_language", norwegian ? "norwegian" : "english",
                               "-AppleLanguages", norwegian ? "(nb)" : "(en)",
                               "-AppleLocale", norwegian ? "nb_NO" : "en_US"]
        app.launch()
        XCTAssertTrue(element("welcome.start").waitForExistence(timeout: 15))
        if ProcessInfo.processInfo.environment["DEMO_CAPTURE"] == "1" {
            for name in ["demo-go", "demo-done", "demo-segments.txt"] {
                try? FileManager.default.removeItem(at: documents.appendingPathComponent(name))
            }
            try Data().write(to: documents.appendingPathComponent("demo-ready"))
            try waitFor { FileManager.default.fileExists(atPath: self.documents.appendingPathComponent("demo-go").path) }
        }
        startedAt = Date()
        mark("Welcome")
        pause(2)
        try tap("welcome.start")
        mark("Choose avatar")
        try tap("profile.avatar.lion")
        try tap("profile.next")
        mark("Mia, age 6")
        try tap("profile.age.6")
        let name = app.textFields["profile.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Mia")
        pause()
        try tap("profile.next")
        mark("Choose colour")
        try tap("profile.theme.standard")
        try tap("profile.save")
        mark("Home")
        XCTAssertTrue(element("home.math").waitForExistence(timeout: 10))
        pause(2)
        try tap("home.math")
        for index in 0..<4 {
            try waitFor { self.answerParts().first == String(index) && self.answerParts().last == "ready" }
            let parts = answerParts()
            XCTAssertEqual(parts.count, 4)
            XCTAssertEqual(parts[1], index == 1 || index == 2 ? "game" : "solveResult")
            mark(["Addition", "Ten friends", "Doubles ladybird", "Subtraction"][index])
            pause(2)
            try tap("answer.\(parts[2])", settle: false)
            // Check during the real feedback window, before auto-advance.
            try waitFor(timeout: 2) { self.answerParts().first == String(index) && self.answerParts().last == "fb" }
            XCTAssertTrue((element("ui.state").value as? String ?? "").contains("|feedbackCorrect=true"))
            mark("Correct feedback \(index + 1)")
            pause(1.5)
        }
        try waitFor { self.answerParts().first == "4" && self.answerParts().last == "ready" }
        try tap("exercise.back")
        XCTAssertTrue(element("home.math").waitForExistence(timeout: 10))
        XCTAssertEqual(element("home.math").value as? String, "4 / 20")
        mark("Home with 4 / 20 saved")
        pause(3)
        try tap("home.rewards")
        XCTAssertTrue(element("rewards.title").waitForExistence(timeout: 10))
        mark("Rewards")
        pause(4)
        if ProcessInfo.processInfo.environment["DEMO_CAPTURE"] == "1" {
            try Data().write(to: documents.appendingPathComponent("demo-done"))
            // Leave the final screen visible while the host stops recordVideo.
            pause(8)
        }
    }

    /// Separate reading take: setup stays outside the recording, which begins at Home.
    @MainActor
    func testReadingWalkthrough() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DEMO_RECORDING"] == "1", "Opt-in demo recording")
        continueAfterFailure = false
        let norwegian = ProcessInfo.processInfo.environment["DEMO_LANGUAGE"] == "no"
        app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-demoRecording", "-demoReading",
                               "-geni_app_language", norwegian ? "norwegian" : "english",
                               "-AppleLanguages", norwegian ? "(nb)" : "(en)",
                               "-AppleLocale", norwegian ? "nb_NO" : "en_US"]
        app.launch()
        try tap("welcome.start")
        try tap("profile.avatar.lion")
        try tap("profile.next")
        try tap("profile.age.6")
        let name = app.textFields["profile.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Mia")
        pause()
        try tap("profile.next")
        try tap("profile.theme.standard")
        try tap("profile.save")
        XCTAssertTrue(element("home.reading").waitForExistence(timeout: 10))
        XCTAssertTrue((element("ui.state").value as? String ?? "").contains("active=Mia|theme=standard"))

        if ProcessInfo.processInfo.environment["DEMO_CAPTURE"] == "1" {
            for name in ["demo-go", "demo-done", "demo-segments.txt"] {
                try? FileManager.default.removeItem(at: documents.appendingPathComponent(name))
            }
            try Data().write(to: documents.appendingPathComponent("demo-ready"))
            try waitFor { FileManager.default.fileExists(atPath: self.documents.appendingPathComponent("demo-go").path) }
        }
        startedAt = Date()
        mark("Home: Mia, age 6, lion, yellow")
        pause(2)
        try tap("home.reading", settle: false)
        XCTAssertTrue(element("readingMode.readToMe").waitForExistence(timeout: 10))
        mark("Reading mode choice")
        pause(2)
        try tap("readingMode.readToMe", settle: false)
        XCTAssertTrue(element("reading.playPause").waitForExistence(timeout: 10))
        mark("Read to me: The Little Cat / Den lille katten")
        let initialWord = readingWordIndex()
        pause(9)
        let finalWord = readingWordIndex()
        XCTAssertGreaterThan(finalWord, initialWord + 2, "Real speech must advance the word highlighting")
        XCTAssertTrue((element("ui.state").value as? String ?? "").contains("playing:true"))
        mark("Highlighting verified: word \(initialWord) → \(finalWord)")
        pause(1)
        if ProcessInfo.processInfo.environment["DEMO_CAPTURE"] == "1" {
            try Data().write(to: documents.appendingPathComponent("demo-done"))
            pause(8)
        }
    }

    private func readingWordIndex() -> Int {
        let state = element("ui.state").value as? String ?? ""
        let reading = state.components(separatedBy: "|").first { $0.hasPrefix("rd=") } ?? ""
        let parts = reading.components(separatedBy: ",")
        return parts.count > 1 ? Int(parts[1]) ?? -1 : -1
    }

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func answerParts() -> [String] {
        let state = element("ui.state").value as? String ?? ""
        let exercise = state.components(separatedBy: "|").first { $0.hasPrefix("ex=") } ?? ""
        return String(exercise.dropFirst(3)).components(separatedBy: ";")
    }

    private func tap(_ id: String, settle: Bool = true) throws {
        let target = element(id)
        try waitFor { target.exists && target.isHittable }
        target.tap()
        if settle { pause() }
    }

    private func waitFor(timeout: TimeInterval = 60, _ condition: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("Demo did not reach its next state: \(element("ui.state").value ?? "missing")")
        throw NSError(domain: "DemoRecording", code: 1)
    }

    private func pause(_ seconds: TimeInterval = 1.25) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func mark(_ segment: String) {
        let line = String(format: "%.1f %@\n", Date().timeIntervalSince(startedAt), segment)
        print("DEMO \(line)")
        let url = documents.appendingPathComponent("demo-segments.txt")
        var data = (try? Data(contentsOf: url)) ?? Data()
        data.append(Data(line.utf8))
        try? data.write(to: url)
    }
}
#endif
