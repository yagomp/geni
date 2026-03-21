import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func levelUp() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            await MainActor.run { gen.impactOccurred(intensity: 0.7) }
            try? await Task.sleep(for: .seconds(0.1))
            await MainActor.run { gen.impactOccurred(intensity: 1.0) }
        }
    }

    static func badgeUnlock() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }

    static func chapterStart() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(0.08))
            await MainActor.run { gen.impactOccurred(intensity: 0.6) }
        }
    }

    static func specialChapter() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            await MainActor.run { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            try? await Task.sleep(for: .seconds(0.1))
            await MainActor.run { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        }
    }

    static func correctAnswer() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func wrongAnswer() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func streakMilestone() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            await MainActor.run { gen.impactOccurred(intensity: 0.8) }
            try? await Task.sleep(for: .seconds(0.15))
            await MainActor.run { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }

    static func dragDrop() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func coinReward() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        Task {
            try? await Task.sleep(for: .seconds(0.05))
            await MainActor.run { gen.impactOccurred(intensity: 0.5) }
        }
    }
}
