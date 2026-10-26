import SwiftUI

/// Weekly activity, lifetime progress and school focus for one child's parent progress card.
struct ParentChildInsights: View {
    @Bindable var viewModel: AppViewModel
    let profile: ChildProfile
    let chapters: [ChapterProgress]
    let rewards: RewardState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ParentWeekRows(profile: profile, summary: summary, topic: topic)

            VStack(alignment: .leading, spacing: 12) {
                ParentProgressHeading(text: L.t("All time", no: "Totalt", es: "Desde el inicio", pt: "Desde o início"))
                HStack(alignment: .top, spacing: 8) {
                    ParentProgressStat(
                        emoji: "⭐", value: "\(chapters.filter { $0.status == .completed }.count)",
                        label: L.t("Chapters", no: "Kapitler", es: "Capítulos", pt: "Capítulos"), color: GeniColor.yellow
                    )
                    ParentProgressStat(
                        emoji: "🔥", value: "\(rewards.streakCount)",
                        label: L.t("Current streak", no: "Rekke nå", es: "Racha actual", pt: "Série atual"), color: GeniColor.orange
                    )
                    ParentProgressStat(
                        emoji: "⚡", value: "\(ParentInsights.lifetimeXP(for: rewards))",
                        label: L.s(.xp), color: GeniColor.cyan
                    )
                }
            }
            .padding(.top, 16)
            .overlay(alignment: .top) {
                Rectangle().fill(GeniColor.hairline).frame(height: 1)
            }

            ParentFocusPicker(viewModel: viewModel, profile: profile)
        }
    }

    private var summary: WeekSummary {
        ParentInsights.weekSummary(
            chapters: chapters,
            readings: viewModel.persistence.loadAllReadingSessions(for: profile.id)
        )
    }

    /// Ages 7+ follow the math topics; younger children follow the games.
    private var topic: MathTopic? {
        profile.age >= 7 ? viewModel.persistence.loadTopicProgress(for: profile.id).currentTopic() : nil
    }
}

private struct ParentWeekRows: View {
    let profile: ChildProfile
    let summary: WeekSummary
    let topic: MathTopic?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ParentProgressHeading(text: L.t("This week", no: "Denne uken", es: "Esta semana", pt: "Esta semana"))

            // One compact row: the whole week at a glance
            HStack(alignment: .top, spacing: 6) {
                weeklyStats(minimumWidth: 0)
            }

            if let strongest = summary.strongest {
                row("💪", L.t("Strongest", no: "Sterkest", es: "Más fuerte", pt: "Mais forte"),
                    "\(strongest.emoji) \(strongest.displayName)")
            }
            if let hardest = summary.hardest {
                row("🧗", L.t("Hardest", no: "Vanskeligst", es: "Más difícil", pt: "Mais difícil"),
                    "\(hardest.emoji) \(hardest.displayName)")
            }
            if let nextValue {
                row("➡️", L.t("Next", no: "Neste", es: "Siguiente", pt: "Próximo"), nextValue)
            }
        }
    }

    @ViewBuilder
    private func weeklyStats(minimumWidth: CGFloat) -> some View {
        ParentProgressStat(
            emoji: "📅", value: "\(summary.daysPracticed)/7",
            label: L.t("Days", no: "Dager", es: "Días", pt: "Dias"), color: GeniColor.blue
        )
        .frame(minWidth: minimumWidth)
        ParentProgressStat(
            emoji: "✏️", value: "\(summary.exercisesDone)",
            label: L.t("Exercises", no: "Oppgaver", es: "Ejercicios", pt: "Exercícios"), color: GeniColor.orange
        )
        .frame(minWidth: minimumWidth)
        ParentProgressStat(
            emoji: "🎯", value: summary.accuracy.map { "\($0)%" } ?? "–",
            label: L.t("Correct", no: "Riktig", es: "Aciertos", pt: "Acertos"), color: GeniColor.green
        )
        .frame(minWidth: minimumWidth)
        if profile.readingMode != .hidden {
            ParentProgressStat(
                emoji: "📖", value: "\(summary.readingSessions)",
                label: L.s(.readingSection), color: GeniColor.purple
            )
            .frame(minWidth: minimumWidth)
        }
    }

    private var nextValue: String? {
        if let topic { return "\(topic.emoji) \(topic.displayName)" }
        let topics = ParentInsights.upcomingTopics(for: profile)
        guard !topics.isEmpty else { return nil }
        return topics.map { "\($0.emoji) \($0.name)" }.joined(separator: "\n")
    }

    private func row(_ emoji: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(emoji).font(.system(size: 24)).frame(width: 28)
            Text(label)
                .font(.system(.body, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 76, alignment: .leading)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(GeniColor.border)
        .frame(minHeight: 48)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct ParentProgressHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(GeniColor.border)
    }
}

private struct ParentProgressStat: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: 16))
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(GeniColor.border)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
        .clipShape(GeniShape())
        .overlay(GeniShape().stroke(color.opacity(0.2), lineWidth: 2).allowsHitTesting(false))
        .accessibilityElement(children: .combine)
    }
}

/// Multi-select chips: the topics school is working on now, favoured in this child's daily chapters.
private struct ParentFocusPicker: View {
    @Bindable var viewModel: AppViewModel
    let profile: ChildProfile
    @State private var focus: [String]?

    init(viewModel: AppViewModel, profile: ChildProfile) {
        self.viewModel = viewModel
        self.profile = profile
        _focus = State(initialValue: profile.focusGames)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.t("School is working on", no: "Skolen jobber med", es: "La escuela trabaja en", pt: "A escola trabalha em"))
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.black)
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(FocusTopic.available(forAge: profile.age), id: \.self) { topic in
                    chip(topic)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func chip(_ topic: FocusTopic) -> some View {
        let selected = ParentInsights.isFocused(topic, focus: focus, age: profile.age)
        return Button {
            HapticManager.selection()
            focus = ParentInsights.toggling(topic, focus: focus, age: profile.age)
            var updated = profile
            updated.focusGames = focus
            viewModel.saveProfile(updated)
        } label: {
            HStack(spacing: 6) {
                Text(topic.emoji).font(.system(size: 16))
                Text(topic.name)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.border)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 40)
            .selectableTile(isSelected: selected, tint: GeniColor.cyan)
        }
        .buttonStyle(KidPressStyle())
        .accessibilityIdentifier("parent.focus.\(topic.rawValue)")
    }
}
