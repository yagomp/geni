import CoreHaptics
import UIKit

/// Short, quiet tactile moments. All entry points share the parent and automation gates.
@MainActor
enum HapticManager {
    static let enabledKey = "geni_haptics_enabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if !newValue { playback?.stop(shutdown: true) }
        }
    }

    private static var canPlay: Bool {
        let process = ProcessInfo.processInfo
        return isEnabled
            && !process.arguments.contains("-uiTest")
            && !process.arguments.contains("-designPreview")
            && process.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
    }

    private static var playback: Playback?

    private static func preparedPlayback() -> Playback {
        if let playback { return playback }
        let prepared = Playback()
        playback = prepared
        return prepared
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard canPlay else { return }
        let prepared = preparedPlayback()
        prepared.stop()
        prepared.impact(style, intensity: 0.5)
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        switch type {
        case .success: correctAnswer()
        case .error, .warning: wrongAnswer()
        @unknown default: selection()
        }
    }

    static func selection() {
        guard canPlay else { return }
        let prepared = preparedPlayback()
        prepared.stop()
        prepared.selection.selectionChanged()
        prepared.selection.prepare()
    }

    /// Notes have a slightly weightier, less sharp landing than a coin's light clink.
    static func coinDrop(note: Bool = false) {
        play([
            Pulse(0, note ? 0.38 : 0.24, note ? 0.4 : 0.75),
            Pulse(0.045, note ? 0.16 : 0.1, 0.55)
        ])
    }

    static func countTick() { play([Pulse(0, 0.12, 0.45)]) }
    static func robotStep() { play([Pulse(0, 0.2, 0.35)]) }
    static func robotArrive() { play([Pulse(0, 0.25, 0.4), Pulse(0.09, 0.4, 0.7)]) }
    static func snap() { play([Pulse(0, 0.32, 0.65), Pulse(0.035, 0.12, 0.45)]) }

    /// At most twelve rising taps, finishing within 0.9 seconds even for a large reward.
    static func coinRipple(count: Int) {
        guard count > 0 else { return }
        let taps = min(count, 12)
        let interval = min(0.09, 0.9 / Double(max(taps - 1, 1)))
        play((0..<taps).map { index in
            let rise = Float(index) / Float(max(taps - 1, 1))
            return Pulse(Double(index) * interval, 0.16 + rise * 0.24, 0.35 + rise * 0.4)
        })
    }

    /// A small accelerating drum roll followed by a bright, gentle finish (0.62 seconds).
    static func celebration() {
        play([
            Pulse(0, 0.18, 0.25), Pulse(0.14, 0.21, 0.3),
            Pulse(0.26, 0.25, 0.35), Pulse(0.36, 0.29, 0.4),
            Pulse(0.44, 0.33, 0.45), Pulse(0.5, 0.38, 0.55),
            Pulse(0.62, 0.5, 0.7)
        ])
    }

    static func levelUp() { celebration() }
    static func badgeUnlock() { celebration() }
    static func streakMilestone() { celebration() }
    static func chapterStart() { play([Pulse(0, 0.3, 0.4), Pulse(0.08, 0.18, 0.4)]) }
    static func specialChapter() { celebration() }
    static func correctAnswer() { play([Pulse(0, 0.24, 0.45), Pulse(0.1, 0.38, 0.65)]) }

    /// A low, fading wobble that invites another try rather than sounding an alarm.
    static func wrongAnswer() {
        play([Pulse(0, 0.24, 0.1), Pulse(0.09, 0.18, 0.05), Pulse(0.2, 0.1, 0.1)])
    }

    static func dragDrop() { snap() }
    static func coinReward() { coinDrop() }

    private struct Pulse {
        let time: TimeInterval
        let intensity: Float
        let sharpness: Float

        init(_ time: TimeInterval, _ intensity: Float, _ sharpness: Float) {
            self.time = time
            self.intensity = intensity
            self.sharpness = sharpness
        }

        var event: CHHapticEvent {
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: time)
        }
    }

    private static func play(_ pulses: [Pulse]) {
        guard canPlay, !pulses.isEmpty else { return }
        preparedPlayback().play(pulses)
    }

    /// One lazily prepared engine and reusable UIKit generators for the entire app.
    private final class Playback {
        private let engine: CHHapticEngine?
        private var player: (any CHHapticPatternPlayer)?
        private var fallbackTask: Task<Void, Never>?
        private var impacts: [Int: UIImpactFeedbackGenerator] = [:]
        let selection = UISelectionFeedbackGenerator()

        init() {
            if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                engine = try? CHHapticEngine()
                engine?.playsHapticsOnly = true
                engine?.isAutoShutdownEnabled = true
                try? engine?.start()
            } else {
                engine = nil
            }
            selection.prepare()
        }

        func stop(shutdown: Bool = false) {
            fallbackTask?.cancel()
            fallbackTask = nil
            try? player?.stop(atTime: CHHapticTimeImmediate)
            player = nil
            if shutdown { engine?.stop(completionHandler: nil) }
        }

        func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
            let generator: UIImpactFeedbackGenerator
            if let cached = impacts[style.rawValue] {
                generator = cached
            } else {
                generator = UIImpactFeedbackGenerator(style: style)
                impacts[style.rawValue] = generator
                generator.prepare()
            }
            generator.impactOccurred(intensity: intensity)
            generator.prepare()
        }

        func play(_ pulses: [Pulse]) {
            // A new moment replaces an unfinished one, avoiding stacked vibrations.
            stop()
            if let engine {
                do {
                    // Idempotent start also recovers after idle shutdown, interruption or server reset.
                    try engine.start()
                    let pattern = try CHHapticPattern(events: pulses.map(\.event), parameters: [])
                    let next = try engine.makePlayer(with: pattern)
                    try next.start(atTime: CHHapticTimeImmediate)
                    player = next
                    return
                } catch {
                    // Unsupported hardware and temporary engine failures use the same gentle rhythm.
                }
            }
            fallbackTask = Task { @MainActor [weak self] in
                var previous: TimeInterval = 0
                for pulse in pulses {
                    do {
                        try await Task.sleep(for: .seconds(pulse.time - previous))
                    } catch { return }
                    guard !Task.isCancelled, HapticManager.canPlay, let self else { return }
                    impact(pulse.sharpness < 0.4 ? .soft : .light, intensity: CGFloat(pulse.intensity))
                    previous = pulse.time
                }
            }
        }
    }
}
