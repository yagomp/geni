import SwiftUI

#if DEBUG
import Security

/// Debug-only hooks for GeniUITests. Inert unless the app is launched with `-uiTest` / `-uiTestReset`.
enum UITestSupport {
    static var isActive: Bool { ProcessInfo.processInfo.arguments.contains("-uiTest") }

    /// `-uiTestReset` wipes persisted state so every UI test starts from a fresh install.
    static func resetIfRequested() {
        // Design previews use their own local store; never reset real profiles or iCloud.
        guard DesignPreview.screen == nil else { return }
        guard ProcessInfo.processInfo.arguments.contains("-uiTestReset") else { return }
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        let pinQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.yagomp.geni.parentPin"
        ]
        SecItemDelete(pinQuery as CFDictionary)
        let cloud = NSUbiquitousKeyValueStore.default
        for key in cloud.dictionaryRepresentation.keys { cloud.removeObject(forKey: key) }
        cloud.synchronize()
    }
}

extension ChapterViewModel {
    /// "<index>;<format>;<what to tap next>;<fb|ready>" so a test can answer any exercise format correctly.
    var uiTestAnswerKey: String {
        guard let exercise = currentExercise else { return "\(currentIndex);done;;ready" }
        let target: String
        switch exercise.format {
        case .missingNumber:
            target = "\(exercise.missingNumberCorrectAnswer)"
        case .trueFalse:
            target = exercise.trueFalseIsCorrect ? "1" : "0"
        case .comparison, .compareGroups:
            target = "\(exercise.options[0])"
        case .evenOddSort:
            target = evenOddStep == 0 ? "\(exercise.correctAnswer)" : (exercise.correctAnswer % 2 == 0 ? "0" : "1")
        case .matchConnect, .clockMatch:
            target = (exercise.correctMatchIndices ?? []).map(String.init).joined(separator: ",")
        default:
            target = "\(exercise.correctAnswer)"
        }
        return "\(currentIndex);\(exercise.format.rawValue);\(target);\(showFeedback ? "fb" : "ready")"
    }
}

extension AppViewModel {
    var uiTestState: String {
        var parts = [
            "screen=\(currentScreen)",
            "active=\(persistence.activeProfile?.nickname ?? "")",
            "theme=\(ThemeManager.shared.current.rawValue)",
            "coins=\(rewardState.coins)",
            "level=\(rewardState.level)",
            "badges=\(rewardState.badgesUnlocked.count)",
            "profiles=\(persistence.profiles.map(\.nickname).joined(separator: ","))",
            "coinsBy=" + persistence.profiles.map { "\($0.nickname):\(persistence.loadRewardState(for: $0.id).coins)" }.joined(separator: ","),
            "rewardsOpen=\(showRewards)",
            "settingsOpen=\(showParentSettings)"
        ]
        if let chapterViewModel { parts.append("ex=\(chapterViewModel.uiTestAnswerKey)") }
        if let vm = readingViewModel {
            parts.append("rd=\(vm.mode.rawValue),\(vm.currentWordIndex),\(vm.words.count),playing:\(vm.isPlaying),paused:\(vm.isPaused),done:\(vm.isCompleted),matched:\(vm.matchedWordCount),err:\(vm.feedbackTone == .error ? vm.feedbackMessage : "")")
        }
        return parts.joined(separator: "|")
    }
}
extension View {
    /// Exposes `AppViewModel` state to XCUITest as one hidden accessibility element (DEBUG + `-uiTest` only).
    @ViewBuilder
    func uiTestStateOverlay(_ viewModel: AppViewModel) -> some View {
        if UITestSupport.isActive {
            overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: 4, height: 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("ui.state")
                    .accessibilityLabel("ui.state")
                    .accessibilityValue(viewModel.uiTestState)
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }
}
#endif
