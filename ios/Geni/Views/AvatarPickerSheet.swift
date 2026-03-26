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
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AvatarOption.all) { avatar in
                        Button {
                            HapticManager.selection()
                            viewModel.updateAvatar(avatar.id)
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Text(avatar.emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 64, height: 64)

                                if currentAvatarId == avatar.id {
                                    Circle()
                                        .fill(avatar.color)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .foregroundStyle(.black)
            }
            .background(GeniColor.lightYellow.ignoresSafeArea())
            .navigationTitle(L.s(.chooseAvatar))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("❌")
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
