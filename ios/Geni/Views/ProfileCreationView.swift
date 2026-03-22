import SwiftUI

struct ProfileCreationView: View {
    let onComplete: (ChildProfile) -> Void
    var editingProfile: ChildProfile? = nil
    var onBack: (() -> Void)? = nil

    @State private var nickname: String = ""
    @State private var age: Int = 6
    @State private var selectedAvatar: String = "lion"
    @State private var selectedOperations: Set<MathOperation> = Set(MathOperation.recommended(for: 6))
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GeniColor.yellow.ignoresSafeArea()

            VStack(spacing: 16) {
                    HStack {
                        if let onBack {
                            Button {
                                HapticManager.selection()
                                onBack()
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.title3.bold())
                                    .foregroundStyle(GeniColor.border)
                                    .frame(width: 44, height: 44)
                                    .background(GeniColor.card)
                                    .overlay(
                                        Rectangle()
                                            .stroke(GeniColor.border, lineWidth: 3)
                                    )
                                    .background(
                                        Rectangle()
                                            .fill(GeniColor.border)
                                            .offset(x: 3, y: 3)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Text(editingProfile != nil ? L.s(.editProfile) : L.s(.createProfile))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    VStack(spacing: 6) {
                        Text(L.s(.nickname))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField(L.s(.nicknamePlaceholder), text: $nickname)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .padding(12)
                            .background(GeniColor.card)
                            .overlay(
                                Rectangle()
                                    .stroke(GeniColor.border, lineWidth: 3)
                            )
                            .background(
                                Rectangle()
                                    .fill(GeniColor.cyan)
                                    .offset(x: 4, y: 4)
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                    }

                    VStack(spacing: 6) {
                        Text(L.s(.age))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            ForEach(5...10, id: \.self) { a in
                                Button {
                                    HapticManager.selection()
                                    age = a
                                } label: {
                                    Text("\(a)")
                                        .font(.system(.title3, design: .rounded, weight: .bold))
                                        .foregroundStyle(age == a ? .white : GeniColor.border)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(age == a ? GeniColor.cyan : GeniColor.card)
                                        .overlay(
                                            Rectangle()
                                                .stroke(GeniColor.border, lineWidth: 3)
                                        )
                                        .background(
                                            age == a ? AnyView(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3)) : AnyView(EmptyView())
                                        )
                                }
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Text(L.s(.chooseAvatar))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(AvatarOption.all) { avatar in
                                Button {
                                    HapticManager.selection()
                                    selectedAvatar = avatar.id
                                } label: {
                                    Text(avatar.emoji)
                                        .font(.system(size: 32))
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .background(.white)
                                        .overlay(
                                            Rectangle()
                                                .stroke(selectedAvatar == avatar.id ? avatar.color : GeniColor.border, lineWidth: selectedAvatar == avatar.id ? 4 : 2)
                                        )
                                        .background(
                                            selectedAvatar == avatar.id ? AnyView(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3)) : AnyView(EmptyView())
                                        )
                                        .scaleEffect(selectedAvatar == avatar.id ? 1.08 : 1.0)
                                        .animation(.snappy, value: selectedAvatar)
                                }
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Text(L.s(.operations))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            ForEach(MathOperation.allCases, id: \.rawValue) { op in
                                Button {
                                    HapticManager.selection()
                                    if selectedOperations.contains(op) {
                                        if selectedOperations.count > 1 {
                                            selectedOperations.remove(op)
                                        }
                                    } else {
                                        selectedOperations.insert(op)
                                    }
                                } label: {
                                    Text(op.symbol)
                                        .font(.system(.title3, design: .rounded, weight: .black))
                                        .foregroundStyle(selectedOperations.contains(op) ? .white : GeniColor.border)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(selectedOperations.contains(op) ? GeniColor.green : GeniColor.card)
                                        .overlay(
                                            Rectangle()
                                                .stroke(GeniColor.border, lineWidth: selectedOperations.contains(op) ? 4 : 2)
                                        )
                                        .background(
                                            selectedOperations.contains(op) ? AnyView(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3)) : AnyView(EmptyView())
                                        )
                                        .scaleEffect(selectedOperations.contains(op) ? 1.05 : 1.0)
                                        .animation(.snappy, value: selectedOperations)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    Button {
                        HapticManager.impact(.medium)
                        let profile: ChildProfile
                        if var existing = editingProfile {
                            existing.nickname = nickname
                            existing.age = age
                            existing.avatarId = selectedAvatar
                            existing.operationsEnabled = Array(selectedOperations)
                            profile = existing
                        } else {
                            var newProfile = ChildProfile(nickname: nickname, age: age, avatarId: selectedAvatar)
                            newProfile.operationsEnabled = Array(selectedOperations)
                            profile = newProfile
                        }
                        onComplete(profile)
                    } label: {
                        HStack(spacing: 10) {
                            Text(L.s(.letsGo))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(BrutalistButton(color: GeniColor.green))
                    .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(nickname.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .onAppear {
            if let profile = editingProfile {
                nickname = profile.nickname
                age = profile.age
                selectedAvatar = profile.avatarId
                selectedOperations = Set(profile.operationsEnabled)
            }
        }
        .onChange(of: age) { _, newAge in
            selectedOperations = Set(MathOperation.recommended(for: newAge))
        }
    }
}
