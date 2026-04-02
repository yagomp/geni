import SwiftUI

struct AvatarPickerSheet: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var currentAvatarId: String {
        viewModel.persistence.activeProfile?.avatarId ?? "lion"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AvatarOption.all) { avatar in
                            avatarButton(avatar)
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AvatarOption.extras) { avatar in
                            avatarButton(avatar)
                        }
                    }
                }
                .padding(20)
            }
            .background(GeniColor.lightYellow.ignoresSafeArea())
            .safeAreaInset(edge: .top) {
                HStack {
                    Text(L.s(.chooseAvatar))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(.black)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("❌")
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(GeniColor.lightYellow)
            }
        }
        .presentationDetents([.medium])
    }

    private func avatarButton(_ avatar: AvatarOption) -> some View {
        Button {
            HapticManager.selection()
            viewModel.updateAvatar(avatar.id)
            dismiss()
        } label: {
            Text(avatar.emoji)
                .font(.system(size: 40))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(currentAvatarId == avatar.id ? avatar.color.opacity(0.2) : .white)
                .overlay(
                    Rectangle()
                        .stroke(currentAvatarId == avatar.id ? avatar.color : GeniColor.border, lineWidth: currentAvatarId == avatar.id ? 4 : 2)
                )
        }
        .foregroundStyle(.black)
    }
}
