import SwiftUI

/// Profile creation in three fixed steps: avatar → name + age → colours.
/// Back keeps the draft; nothing is saved until `profile.save`.
struct ProfileOnboardingFlow: View {
    let onComplete: (ChildProfile) -> Void
    let onBack: (() -> Void)?
    @State private var draft: ProfileDraft
    @State private var step: Int
    @State private var forward = true
    @FocusState private var nameFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(existingNames: [String], onComplete: @escaping (ChildProfile) -> Void, onBack: (() -> Void)?) {
        self.onComplete = onComplete
        self.onBack = onBack
        let draft = ProfileDraft(existingNames: existingNames)
        var step = 1
        #if DEBUG
        if let previewStep = DesignPreview.onboardingStep {
            step = previewStep
            if previewStep > 1 { draft.nickname = "Daniel" }
        }
        #endif
        _draft = State(initialValue: draft)
        _step = State(initialValue: step)
    }

    var body: some View {
        StepScaffold(step: step, title: title, accent: draft.theme.previewAccent, onBack: backAction,
                     primary: primary, allowsScrolling: step != 1) { availableSize in
            stepContent(availableSize: availableSize)
                .id(step)
                .transition(stepTransition)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("profile.step.\(step)")
        }
        .background(draft.screenBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: draft.theme)
        .task(id: step) {
            #if DEBUG
            // Keep the name/age screen visible without a keyboard in marketing captures.
            if DesignPreview.onboardingStep != nil { return }
            #endif
            guard step == 2 else {
                nameFocused = false
                return
            }
            try? await Task.sleep(for: .milliseconds(350))
            nameFocused = true
        }
    }

    // MARK: Navigation

    private var title: String {
        switch step {
        case 1: return L.s(.chooseAvatar)
        case 2: return L.s(.whosPlaying)
        default: return L.s(.colorsTitle)
        }
    }

    private var backAction: (() -> Void)? {
        step == 1 ? onBack : { go(to: step - 1) }
    }

    private var primary: StepPrimaryButton {
        switch step {
        case 1:
            return StepPrimaryButton(title: L.s(.next), isEnabled: true, identifier: "profile.next") { go(to: 2) }
        case 2:
            return StepPrimaryButton(title: L.s(.next), isEnabled: draft.canSave, identifier: "profile.next") { go(to: 3) }
        default:
            return StepPrimaryButton(title: L.s(.letsGo), showsPlay: true, isEnabled: draft.canSave, identifier: "profile.save") {
                guard draft.canSave else { return }
                onComplete(draft.profile)
            }
        }
    }

    private func go(to newStep: Int) {
        HapticManager.selection()
        forward = newStep > step
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.85)) {
            step = newStep
        }
    }

    private var stepTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var avatarSelection: Binding<String> {
        Binding(get: { draft.avatarId }, set: { draft.selectAvatar($0) })
    }

    // MARK: Steps

    @ViewBuilder
    private func stepContent(availableSize: CGSize) -> some View {
        switch step {
        case 1: avatarStep(availableSize: availableSize)
        case 2: nameAgeStep(availableSize: availableSize)
        default: lookStep(availableSize: availableSize)
        }
    }

    private func avatarStep(availableSize: CGSize) -> some View {
        let expanded = iPadScale.isIPad && availableSize.width >= 620
        let count = expanded ? (availableSize.width > availableSize.height ? 7 : 6) : (availableSize.width >= 380 || iPadScale.isIPad ? 6 : 5)
        let rows = (AvatarOption.catalog.count + count - 1) / count
        // Room between cards so each avatar reads as its own card.
        let gap: CGFloat = expanded ? 28 : 18
        // Leave room for the selection scale, check dot and soft shadow.
        let tileSize = min(expanded ? 120 : .infinity, min((availableSize.width - (expanded ? 40 : 24) - CGFloat(count - 1) * gap) / CGFloat(count),
                           (availableSize.height - (expanded ? 40 : 24) - CGFloat(rows - 1) * gap) / CGFloat(rows)))
        let columns = Array(repeating: GridItem(.fixed(tileSize), spacing: gap), count: count)
        // Compact steps retain their original row spacing; large tiles use a steady gap.
        let rowGap = expanded ? gap : min(44, max(gap, (availableSize.height - 24 - CGFloat(rows) * tileSize) / CGFloat(rows - 1) * 0.8))
        return AvatarGrid(options: AvatarOption.catalog, selection: avatarSelection, idPrefix: "profile.avatar",
                          columns: columns, spacing: rowGap, emojiSize: tileSize * 0.62,
                          tileSize: expanded ? tileSize : nil)
            .padding(expanded ? 20 : 12)
    }

    private func nameAgeStep(availableSize: CGSize) -> some View {
        let expanded = iPadScale.isIPad && availableSize.width >= 620
        let controlHeight: CGFloat = expanded ? min(104, max(64, availableSize.height * 0.22)) : 56
        return VStack(spacing: expanded ? 12 : 0) {
            HStack(spacing: 12) {
                Button { go(to: 1) } label: {
                    AvatarPreview(avatar: AvatarOption.find(draft.avatarId), size: controlHeight, bounces: false)
                }
                .buttonStyle(KidPressStyle())
                .accessibilityLabel(L.s(.chooseAvatar))

                ProfileNameField(draft: draft, height: controlHeight) {
                    if draft.canSave { go(to: 3) }
                }
                .focused($nameFocused)
            }
            ProfileNameMessage(draft: draft, height: 20)
            // Keep the selected chip's check dot below the age label.
            VStack(alignment: .leading, spacing: 12) {
                ProfileSectionLabel(text: L.s(.age))
                    .frame(height: expanded ? 32 : 20)
                AgeChips(draft: draft, height: controlHeight)
            }
        }
    }

    private func lookStep(availableSize: CGSize) -> some View {
        let expanded = iPadScale.isIPad && availableSize.width >= 620
        let tileHeight = min(expanded ? 240.0 : 176.0, max(128.0, (availableSize.height - 32) * 0.6))
        return ThemeTiles(draft: draft, height: tileHeight)
            .frame(maxHeight: .infinity)
    }
}
