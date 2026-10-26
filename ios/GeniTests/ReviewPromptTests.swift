import Foundation
import Testing
@testable import Geni

struct ReviewPromptTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let cooldown: TimeInterval = 120 * 24 * 60 * 60

    private func eligible(
        chapters: Int = 5,
        lastRequest: Date? = nil,
        lastVersion: String? = nil,
        version: String? = "1.3.0",
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) -> Bool {
        ReviewPrompt.shouldRequest(
            totalChaptersCompleted: chapters,
            lastRequest: lastRequest,
            lastRequestedVersion: lastVersion,
            currentVersion: version,
            now: now,
            arguments: arguments,
            environment: environment
        )
    }

    @Test func firstRequestNeedsFiveCompletedChapters() {
        #expect(!eligible(chapters: 0))
        #expect(!eligible(chapters: 4))
        #expect(eligible(chapters: 5))
        #expect(eligible(chapters: 20))
    }

    @Test func newVersionStillWaitsTheFullCooldown() {
        #expect(!eligible(lastRequest: now.addingTimeInterval(-cooldown + 1), lastVersion: "1.2.0"))
        #expect(eligible(lastRequest: now.addingTimeInterval(-cooldown), lastVersion: "1.2.0"))
        #expect(eligible(lastRequest: now.addingTimeInterval(-cooldown - 1), lastVersion: "1.2.0"))
    }

    @Test func sameVersionNeverRequestsAgain() {
        #expect(!eligible(lastVersion: "1.3.0"))
        #expect(!eligible(lastRequest: now.addingTimeInterval(-2 * cooldown), lastVersion: "1.3.0"))
    }

    @Test func recentOrFutureDatesBlockEvenWithoutAVersionRecord() {
        #expect(!eligible(lastRequest: now))
        #expect(!eligible(lastRequest: now.addingTimeInterval(1)))
        #expect(eligible(lastRequest: now.addingTimeInterval(-cooldown)))
    }

    @Test(arguments: ["-uiTest", "-designPreview"])
    func automationNeverRequests(argument: String) {
        #expect(!eligible(arguments: ["Geni", argument, "parentDashboard"]))
    }

    @Test func xcodePreviewsNeverRequest() {
        #expect(!eligible(environment: ["XCODE_RUNNING_FOR_PREVIEWS": "1"]))
        #expect(eligible(environment: ["XCODE_RUNNING_FOR_PREVIEWS": "0"]))
    }

    @Test func missingVersionDoesNotConsumeARequest() {
        #expect(!eligible(version: nil))
        #expect(!eligible(version: ""))
    }
}
