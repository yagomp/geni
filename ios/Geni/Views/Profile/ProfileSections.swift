import SwiftUI

// Profile form building blocks shared by the onboarding steps and the edit form.
// They read and write a `ProfileDraft` only.

/// The 64pt name field. The duplicate-name message lives in `ProfileNameMessage`.
struct ProfileNameField: View {
    @Environment(\.geniExpandedLayout) private var expanded
    @Bindable var draft: ProfileDraft
    var height: CGFloat = 64
    var onSubmit: () -> Void = {}

    var body: some View {
        let shape = GeniShape(scale: 0.6)
        TextField(L.s(.nicknamePlaceholder), text: $draft.nickname)
            .font(.system(expanded ? .largeTitle : .title3, design: .rounded, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(GeniColor.card)
            .clipShape(shape)
            .overlay(shape.stroke(draft.isDuplicate ? GeniColor.pink : GeniColor.hairline, lineWidth: draft.isDuplicate ? 2 : 1))
            .shadow(color: GeniColor.border.opacity(0.08), radius: 10, x: 0, y: 4)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .onSubmit(onSubmit)
            .accessibilityIdentifier("profile.name")
    }
}

/// Fixed-height slot under the name field so nothing moves when the message appears.
struct ProfileNameMessage: View {
    let draft: ProfileDraft
    var height: CGFloat = 24

    var body: some View {
        Text(draft.isDuplicate ? L.s(.nameTaken) : " ")
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(GeniColor.pinkDeep)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .accessibilityHidden(!draft.isDuplicate)
    }
}

/// Ages 4–10 in one row of 64pt-tall chips; 6pt gaps keep "10" whole on a 375pt phone.
struct AgeChips: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let draft: ProfileDraft
    var height: CGFloat = 64

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(ProfileDraft.ages), id: \.self) { age in
                Button {
                    HapticManager.selection()
                    draft.setAge(age)
                } label: {
                    Text("\(age)")
                        .font(.system(size: expanded ? 40 : 28, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(GeniColor.border)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .selectableTile(isSelected: draft.age == age, tint: GeniColor.cyan)
                }
                .buttonStyle(KidPressStyle())
                .accessibilityLabel("\(L.s(.age)) \(age)")
                .accessibilityIdentifier("profile.age.\(age)")
            }
        }
    }
}

/// Three big colour swatches, one per theme; no text.
struct ThemeTiles: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let draft: ProfileDraft
    var height: CGFloat = 96

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.25)) { draft.theme = theme }
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .selectableTile(isSelected: draft.theme == theme, tint: theme.previewSwatch,
                                        restingFill: theme.previewSwatch, selectedFill: theme.previewSwatch,
                                        restingShadow: GeniColor.border)
                }
                .buttonStyle(KidPressStyle())
                .accessibilityLabel(theme.displayName)
                .accessibilityAddTraits(draft.theme == theme ? .isSelected : [])
                .accessibilityIdentifier("profile.theme.\(theme.rawValue)")
            }
        }
        // Reserve the selected tile's scale, check dot and soft shadow on both sides.
        .frame(maxWidth: expanded ? 760 : 420)
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

/// The four operations; recommended ones for the age carry a ⭐ corner marker.
struct OperationTiles: View {
    let draft: ProfileDraft

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MathOperation.allCases, id: \.self) { op in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { draft.toggle(op) }
                } label: {
                    Text(op.symbol)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .selectableTile(isSelected: draft.operations.contains(op), tint: op.tileTint)
                        .overlay(alignment: .topLeading) {
                            if draft.isRecommended(op) {
                                Text("⭐")
                                    .font(.system(size: 16))
                                    .offset(x: -7, y: -9)
                                    .accessibilityHidden(true)
                            }
                        }
                }
                .buttonStyle(KidPressStyle())
                .accessibilityLabel(op.displayName)
                .accessibilityIdentifier("profile.op.\(op.rawValue)")
            }
        }
    }
}

private extension MathOperation {
    var tileTint: Color {
        switch self {
        case .addition: return GeniColor.green
        case .subtraction: return GeniColor.blue
        case .multiplication: return GeniColor.purple
        case .division: return GeniColor.orange
        }
    }
}

/// The age-6 optional reading switch.
struct ReadingRow: View {
    @Bindable var draft: ProfileDraft

    var body: some View {
        let shape = GeniShape(scale: 0.6)
        Toggle(isOn: $draft.readingEnabled) {
            Text("📖 \(L.s(.readingProgress))")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.black)
        }
        .tint(GeniColor.green)
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .background(GeniColor.card)
        .clipShape(shape)
        .overlay(shape.stroke(GeniColor.hairline, lineWidth: 1))
        .accessibilityIdentifier("profile.readingEnabled")
    }
}

/// Small bold label above a section.
struct ProfileSectionLabel: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let text: String

    var body: some View {
        Text(text)
            .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
