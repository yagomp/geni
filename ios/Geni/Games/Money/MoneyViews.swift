import SwiftUI

/// The same tangible cash appears in the tray, counter and change scene.
struct MoneyToken: View {
    let denomination: MoneyDenomination
    let currency: MoneyCurrency
    var size: CGFloat = 52

    private var color: Color {
        switch denomination.value {
        case 1: GeniColor.yellow
        case 2: GeniColor.cyan
        case 5: GeniColor.orange
        case 10: GeniColor.pink.soft(0.35)
        case 20: GeniColor.blue.soft(0.3)
        case 50: GeniColor.green.soft(0.3)
        default: GeniColor.cyan
        }
    }

    var body: some View {
        if denomination.form == .coin {
            face(width: size, height: size)
                .background(color, in: Circle())
                .overlay(Circle().stroke(GameStyle.hairline, lineWidth: 1.5))
                .shadow(color: GameStyle.shadow, radius: 5, x: 0, y: 2)
        } else {
            face(width: size * 1.4, height: size * 0.72)
                .background(color, in: GeniShape(scale: 0.4))
                .overlay(GeniShape(scale: 0.4).stroke(GameStyle.hairline, lineWidth: 1.5))
                .shadow(color: GameStyle.shadow, radius: 5, x: 0, y: 2)
        }
    }

    private func face(width: CGFloat, height: CGFloat) -> some View {
        Text(currency.format(denomination.value))
            .font(.system(size: size * 0.36, weight: .black, design: .rounded))
            .foregroundStyle(GeniColor.border)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 4)
            .frame(width: width, height: height)
            .accessibilityLabel(currency.format(denomination.value))
    }
}

private struct MoneyPriceTag: View {
    let amount: Int
    let currency: MoneyCurrency
    let size: CGFloat

    var body: some View {
        Text(currency.format(amount))
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(GeniColor.border)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .gameSurface(GeniColor.yellow.soft(0.35))
    }
}

struct MoneyPayView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let spec: GameSpec
    let payload: MoneyPayPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService
    @State private var counter = MoneyCounter()

    private func scaled(_ value: CGFloat) -> CGFloat { expanded ? value * 1.6 : iPadScale.value(value) }

    var body: some View {
        VStack(spacing: scaled(12)) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                VStack(spacing: scaled(10)) {
                    HStack(spacing: scaled(20)) {
                        Text(payload.item.emoji)
                            .font(.system(size: scaled(44)))
                        MoneyPriceTag(amount: payload.item.price, currency: payload.currency, size: scaled(24))
                    }
                    Rectangle().fill(GameStyle.hairline).frame(height: 2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: scaled(4)), count: 5), spacing: scaled(4)) {
                        ForEach(0..<MoneyCounter.capacity, id: \.self) { index in
                            counterSlot(index)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(L.t("On the counter: \(payload.currency.format(counter.total))", no: "På disken: \(payload.currency.format(counter.total))",
                                            es: "En el mostrador: \(payload.currency.format(counter.total))", pt: "No balcão: \(payload.currency.format(counter.total))"))
                }
            }
            HStack(spacing: scaled(6)) {
                ForEach(payload.tray, id: \.value) { denomination in
                    Button {
                        HapticManager.coinDrop(note: denomination.form == .note)
                        counter.add(denomination)
                    } label: {
                        MoneyToken(denomination: denomination, currency: payload.currency, size: scaled(46))
                            .frame(maxWidth: .infinity)
                            .frame(height: scaled(64))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(GameTileStyle())
                    .disabled(chapterVM.showFeedback || counter.pieces.count == MoneyCounter.capacity)
                    .accessibilityLabel(L.t("Add \(payload.currency.format(denomination.value))", no: "Legg til \(payload.currency.format(denomination.value))",
                                            es: "Añadir \(payload.currency.format(denomination.value))", pt: "Adicionar \(payload.currency.format(denomination.value))"))
                    .accessibilityIdentifier("money.tray.\(denomination.value)")
                }
            }
            GameSubmitButton(value: counter.total, chapterVM: chapterVM, persistence: persistence, isEnabled: !counter.pieces.isEmpty)
                .accessibilityIdentifier("answer.\(counter.total)")
        }
    }

    @ViewBuilder
    private func counterSlot(_ index: Int) -> some View {
        if counter.pieces.indices.contains(index) {
            let denomination = counter.pieces[index]
            Button {
                HapticManager.coinDrop(note: denomination.form == .note)
                counter.remove(at: index)
            } label: {
                MoneyToken(denomination: denomination, currency: payload.currency, size: scaled(38))
                    .frame(maxWidth: .infinity)
                    .frame(height: scaled(44))
                    .contentShape(Rectangle())
            }
            .buttonStyle(GameTileStyle(fill: GeniColor.yellow.soft(0.35), outline: GeniColor.yellow))
            .disabled(chapterVM.showFeedback)
            .accessibilityLabel(L.t("Take back \(payload.currency.format(denomination.value))", no: "Ta tilbake \(payload.currency.format(denomination.value))",
                                    es: "Retirar \(payload.currency.format(denomination.value))", pt: "Retirar \(payload.currency.format(denomination.value))"))
            .accessibilityIdentifier("money.counter.\(index)")
        } else {
            Circle()
                .strokeBorder(GeniColor.lightGray, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                .frame(width: scaled(38), height: scaled(38))
                .frame(height: scaled(44))
                .accessibilityHidden(true)
        }
    }
}

struct MoneyShoppingView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: MoneyShoppingPayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        VStack(spacing: expanded ? 28 : 16) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                HStack(spacing: expanded ? 24 : 12) {
                    ForEach(Array(payload.items.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: expanded ? 18 : 12) {
                            Text(item.emoji).font(.system(size: expanded ? 80 : iPadScale.value(48)))
                            MoneyPriceTag(amount: item.price, currency: payload.currency, size: expanded ? 32 : iPadScale.value(22))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }
}

struct MoneyChangeView: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let exercise: Exercise
    let spec: GameSpec
    let payload: MoneyChangePayload
    let chapterVM: ChapterViewModel
    let persistence: PersistenceService

    var body: some View {
        VStack(spacing: expanded ? 28 : 16) {
            GameQuestion(text: spec.prompt)
            GameSceneCard {
                HStack(spacing: expanded ? 32 : 16) {
                    VStack(spacing: expanded ? 18 : 12) {
                        Text(payload.item.emoji).font(.system(size: expanded ? 80 : iPadScale.value(48)))
                        MoneyPriceTag(amount: payload.item.price, currency: payload.currency, size: expanded ? 32 : iPadScale.value(22))
                    }
                    .frame(maxWidth: .infinity)
                    Image(systemName: "arrow.left")
                        .font(.system(size: expanded ? 40 : iPadScale.value(24), weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .accessibilityHidden(true)
                    MoneyToken(denomination: payload.note, currency: payload.currency, size: expanded ? 104 : iPadScale.value(64))
                        .frame(maxWidth: .infinity)
                }
            }
            GameChoices(choices: payload.choices, exercise: exercise, chapterVM: chapterVM, persistence: persistence)
        }
    }
}
