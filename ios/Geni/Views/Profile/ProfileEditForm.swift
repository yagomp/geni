import SwiftUI

/// Parent-side profile editing: every control on one scrolling page. Back saves a valid draft;
/// an empty or duplicate name just leaves without saving.
struct ProfileEditForm: View {
    let onComplete: (ChildProfile) -> Void
    let onBack: (() -> Void)?
    @State private var draft: ProfileDraft
    @State private var showChooser = false

    init(profile: ChildProfile, existingNames: [String], onComplete: @escaping (ChildProfile) -> Void, onBack: (() -> Void)?) {
        self.onComplete = onComplete
        self.onBack = onBack
        _draft = State(initialValue: ProfileDraft(editing: profile, existingNames: existingNames))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 24) {
                    avatarButton

                    section(L.s(.yourName)) {
                        VStack(spacing: 4) {
                            ProfileNameField(draft: draft)
                            ProfileNameMessage(draft: draft)
                        }
                    }

                    section(L.s(.age)) {
                        AgeChips(draft: draft)
                    }

                    section(L.s(.theme)) {
                        ThemeTiles(draft: draft)
                    }

                    section(L.s(.mathPractice)) {
                        OperationTiles(draft: draft)
                    }

                    if draft.age == 6 {
                        ReadingRow(draft: draft)
                    }
                }
                .padding(.horizontal, iPadScale.padding)
                .padding(.vertical, 16)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StepPrimaryButton(title: L.s(.done), isEnabled: draft.canSave, identifier: "profile.save") {
                guard let original = draft.original, draft.canSave else { return }
                onComplete(draft.apply(to: original))
            }
            .padding(.horizontal, iPadScale.padding)
            .padding(.vertical, 12)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .background(draft.screenBackground)
        }
        .background(draft.screenBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: draft.theme)
        .sheet(isPresented: $showChooser) {
            AvatarChooserSheet(
                selection: Binding(get: { draft.avatarId }, set: { draft.selectAvatar($0) }),
                idPrefix: "profile.avatar",
                background: draft.screenBackground
            )
        }
    }

    private var header: some View {
        HStack {
            if let onBack {
                KidBackButton {
                    HapticManager.selection()
                    if let original = draft.original, draft.canSave {
                        onComplete(draft.apply(to: original))
                    } else {
                        onBack()
                    }
                }
                .accessibilityIdentifier("profile.back")
            } else {
                Color.clear.frame(width: 56, height: 56)
            }
            Spacer()
            Text(L.s(.editProfile))
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.horizontal, iPadScale.padding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var avatarButton: some View {
        Button {
            HapticManager.selection()
            showChooser = true
        } label: {
            AvatarPreview(avatar: AvatarOption.find(draft.avatarId), size: 96)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(GeniColor.yellow))
                        .overlay(Circle().stroke(GeniColor.hairline, lineWidth: 1))
                        .offset(x: 10, y: 10)
                }
        }
        .buttonStyle(KidPressStyle())
        .accessibilityLabel(L.s(.chooseAvatar))
        .accessibilityIdentifier("profile.avatar.more")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            ProfileSectionLabel(text: title)
            content()
        }
    }
}
