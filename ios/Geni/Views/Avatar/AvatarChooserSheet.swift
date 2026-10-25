import SwiftUI

/// The full avatar chooser. A tap selects immediately and the sheet stays open;
/// ✓ or a swipe closes it.
struct AvatarChooserSheet: View {
    @Binding private var selection: String
    private let idPrefix: String
    private let background: Color?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.geniCornerRadius) private var radiusOverride

    /// Edits the active profile's avatar, saving each tap (home, rewards).
    init(viewModel: AppViewModel) {
        _selection = Binding(
            get: { viewModel.persistence.activeProfile?.avatarId ?? AvatarOption.all[0].id },
            set: { viewModel.updateAvatar($0) }
        )
        idPrefix = "avatar"
        background = nil
    }

    /// Edits a draft value (profile creation/editing); nothing is saved here.
    init(selection: Binding<String>, idPrefix: String = "avatar", background: Color? = nil) {
        _selection = selection
        self.idPrefix = idPrefix
        self.background = background
    }

    private var screenBackground: Color { background ?? GeniColor.lightYellow }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AvatarPreview(avatar: AvatarOption.find(selection), size: 120)
                HStack {
                    Spacer()
                    doneButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 16)

            ScrollView {
                AvatarGrid(options: AvatarOption.catalog, selection: $selection, idPrefix: idPrefix)
                    .padding(20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(screenBackground.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var doneButton: some View {
        let shape = GeniShape(scale: 0.6, override: radiusOverride)
        return Button {
            HapticManager.selection()
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(GeniColor.green)
                .clipShape(shape)
                .overlay(shape.stroke(GeniColor.border, lineWidth: 3))
                .background(shape.fill(GeniColor.border).offset(x: 4, y: 4))
        }
        .buttonStyle(KidPressStyle())
        .accessibilityLabel(L.s(.done))
        .accessibilityIdentifier("avatar.sheet.done")
    }
}
