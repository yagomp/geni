import SwiftUI

struct StoryGameView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        if let payload = spec.payload as? StoryPayload {
            VStack(spacing: expanded ? 28 : iPadScale.value(16)) {
                GameQuestion(text: spec.prompt)
                GameSceneCard {
                    switch payload.picture {
                    case .groups(let picture): StoryGroupsScene(picture: picture)
                    case .sharing(let picture): StorySharingScene(picture: picture)
                    }
                }
                GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
            }
        }
    }
}

private struct StoryGroupsScene: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let picture: StoryGroupsPicture

    private var usesRows: Bool { picture.groups > 5 }
    private var columns: Int { usesRows || picture.groups <= 4 ? 2 : 3 }
    private var itemSize: CGFloat { expanded ? 38 : iPadScale.value(usesRows ? 22 : (columns == 3 ? 24 : 28)) }

    var body: some View {
        VStack(spacing: expanded ? 18 : 10) {
            if picture.showsCalculation {
                Text("\(picture.groups) × \(picture.itemsPerGroup)")
                    .font(.system(size: expanded ? 48 : iPadScale.value(30), weight: .black, design: .rounded))
                    .foregroundStyle(GeniColor.border)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: expanded ? 16 : 10), count: columns),
                      spacing: expanded ? 16 : (usesRows ? 6 : 10)) {
                ForEach(0..<picture.groups, id: \.self) { _ in
                    VStack(spacing: 4) {
                        if let character = picture.character {
                            Text(character)
                                .font(.system(size: expanded ? 42 : iPadScale.value(28)))
                        }
                        StoryItemGrid(count: picture.itemsPerGroup, item: picture.item,
                                      columns: usesRows ? picture.itemsPerGroup : min(picture.itemsPerGroup, 3),
                                      size: itemSize)
                    }
                    .padding(expanded ? 12 : (usesRows ? 4 : 7))
                    .frame(maxWidth: .infinity)
                    .gameSurface(GeniColor.yellow.soft(0.22))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("\(picture.groups) boxes with \(picture.itemsPerGroup) items each",
                               no: "\(picture.groups) esker med \(picture.itemsPerGroup) ting i hver",
                               es: "\(picture.groups) cajas con \(picture.itemsPerGroup) objetos en cada una",
                               pt: "\(picture.groups) caixas com \(picture.itemsPerGroup) objetos em cada uma"))
    }
}

private struct StorySharingScene: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let picture: StorySharingPicture

    var body: some View {
        VStack(spacing: expanded ? 20 : 12) {
            StoryItemGrid(count: picture.total, item: picture.item,
                          columns: min(picture.total, picture.total > 24 ? 10 : 8),
                          size: expanded ? 42 : iPadScale.value(25))
            Image(systemName: "arrow.down")
                .font(.system(size: expanded ? 32 : iPadScale.value(20), weight: .black))
                .foregroundStyle(GeniColor.blue)
            HStack(spacing: expanded ? 16 : 8) {
                ForEach(0..<picture.friends, id: \.self) { _ in
                    VStack(spacing: 4) {
                        if let character = picture.character {
                            Text(character)
                                .font(.system(size: expanded ? 42 : iPadScale.value(28)))
                        }
                        ZStack {
                            Ellipse()
                                .fill(GeniColor.cyan.soft(0.4))
                                .overlay(Ellipse().stroke(GameStyle.hairline, lineWidth: 1.5))
                                .shadow(color: GameStyle.shadow, radius: 5, x: 0, y: 2)
                            Ellipse()
                                .stroke(GeniColor.blue.soft(0.6), lineWidth: 1.5)
                                .padding(expanded ? 10 : 6)
                        }
                        .frame(height: expanded ? 60 : iPadScale.value(36))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.t("\(picture.total) items above \(picture.friends) empty plates",
                               no: "\(picture.total) ting over \(picture.friends) tomme tallerkener",
                               es: "\(picture.total) objetos sobre \(picture.friends) platos vacíos",
                               pt: "\(picture.total) objetos por cima de \(picture.friends) pratos vazios"))
    }
}

private struct StoryItemGrid: View {
    let count: Int
    let item: String
    let columns: Int
    let size: CGFloat

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<((count + columns - 1) / columns), id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<min(columns, count - row * columns), id: \.self) { _ in
                        Text(item)
                            .font(.system(size: size))
                            .frame(width: size, height: size)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
