import Foundation

nonisolated enum ReviewPrompt {
    static let lastRequestKey = "geni_last_review_request"
    static let requestedVersionKey = "geni_review_requested_version"

    static func shouldRequest(
        totalChaptersCompleted: Int,
        lastRequest: Date?,
        lastRequestedVersion: String?,
        currentVersion: String?,
        now: Date,
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
        guard !arguments.contains("-uiTest"),
              !arguments.contains("-designPreview"),
              environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1",
              totalChaptersCompleted >= 5,
              let currentVersion, !currentVersion.isEmpty,
              lastRequestedVersion != currentVersion else { return false }

        if let lastRequest {
            return now.timeIntervalSince(lastRequest) >= 120 * 24 * 60 * 60
        }
        return true
    }
}
