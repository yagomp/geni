import SwiftUI

struct CalendarGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? CalendarPayload {
            VStack(spacing: expanded ? 36 : 24) {
                GameQuestion(text: spec.prompt)
                GameSceneCard { scene(payload.scene) }
                choices(payload)
            }
        }
    }

    @ViewBuilder
    private func scene(_ scene: CalendarPayload.Scene) -> some View {
        switch scene {
        case .week(let cells):
            HStack(spacing: expanded ? 8 : 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    WeekdayCard(cell: cell)
                }
            }
        case .month(let name):
            MonthPage(name: name)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: expanded ? 120 : iPadScale.value(84)))
                .minimumScaleFactor(0.5)
        case .solid(let solid):
            SolidFigure(solid: solid, size: expanded ? 220 : iPadScale.value(130))
        }
    }

    @ViewBuilder
    private func choices(_ payload: CalendarPayload) -> some View {
        switch payload.style {
        case .text:
            GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        case .emoji:
            HStack(spacing: 12) {
                ForEach(payload.choices, id: \.value) { choice in
                    GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM, persistence: persistence) {
                        Text(choice.label)
                            .font(.system(size: expanded ? 64 : iPadScale.value(44)))
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        case .solids:
            HStack(spacing: 12) {
                ForEach(payload.choices, id: \.value) { choice in
                    GameChoiceTile(value: choice.value, exercise: exercise, chapterVM: chapterVM,
                                   persistence: persistence, height: 112) {
                        SolidFigure(solid: Solid(rawValue: choice.value) ?? .cube, size: expanded ? 130 : iPadScale.value(80))
                    }
                    .accessibilityLabel(choice.label)
                }
            }
        }
    }
}

/// One day of the week: its short name, a "?" where the answer goes, or empty.
private struct WeekdayCard: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let cell: WeekCell

    var body: some View {
        Text(cell.label)
            .font(.system(size: expanded ? 30 : iPadScale.value(16), weight: .black, design: .rounded))
            .foregroundStyle(GeniColor.border)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, 1)
            .frame(maxWidth: .infinity)
            .frame(height: expanded ? 110 : iPadScale.value(72))
            .background(background, in: GeniShape(scale: 0.4))
            .overlay(GeniShape(scale: 0.4).stroke(GameStyle.hairline, lineWidth: 1.5))
            .accessibilityHidden(cell.state == .blank)
    }

    private var background: Color {
        switch cell.state {
        case .shown: return GeniColor.card
        case .anchor: return GeniColor.cyan
        case .blank: return GeniColor.lightGray
        case .missing: return GeniColor.yellow
        }
    }
}

/// A page torn from a wall calendar with the month's name.
private struct MonthPage: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let name: String

    var body: some View {
        VStack(spacing: 0) {
            GeniColor.pink
                .frame(height: expanded ? 36 : iPadScale.value(24))
            Text(name)
                .font(.system(size: expanded ? 64 : iPadScale.value(40), weight: .black, design: .rounded))
                .foregroundStyle(GeniColor.border)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: expanded ? 110 : iPadScale.value(72))
                .background(GeniColor.card)
        }
        .clipShape(GeniShape(scale: 0.5))
        .overlay(GeniShape(scale: 0.5).stroke(GameStyle.hairline, lineWidth: 1.5))
        .frame(maxWidth: expanded ? 460 : 280)
    }
}
