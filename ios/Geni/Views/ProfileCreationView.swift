import SwiftUI

struct ProfileCreationView: View {
    let onComplete: (ChildProfile) -> Void
    var editingProfile: ChildProfile? = nil
    var onBack: (() -> Void)? = nil

    private var bgColor: Color {
        editingProfile != nil ? GeniColor.background : GeniColor.yellow
    }

    @State private var nickname: String = ""
    @State private var age: Int = 6
    @State private var selectedAvatar: String = "lion"
    @State private var selectedOperations: Set<MathOperation> = Set(MathOperation.recommended(for: 6))
    @State private var avatarBounce: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                    HStack {
                        if let onBack {
                            Button {
                                HapticManager.selection()
                                onBack()
                            } label: {
                                Text("◀️")
                                    .font(.system(size: 20))
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

                ScrollView {
                    VStack(spacing: 20) {

                    Text(editingProfile != nil ? L.s(.editProfile) : L.s(.whosPlaying))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)

                    VStack(spacing: 6) {
                        Text(L.s(.yourName))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField(L.s(.nicknamePlaceholder), text: $nickname)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(14)
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
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            ForEach(5...10, id: \.self) { a in
                                Button {
                                    HapticManager.selection()
                                    age = a
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(a)")
                                            .font(.system(.title3, design: .rounded, weight: .bold))
                                            .foregroundStyle(age == a ? .white : GeniColor.border)
                                    }
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
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(AvatarOption.all) { avatar in
                                Button {
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        selectedAvatar = avatar.id
                                        avatarBounce = avatar.id
                                    }
                                    Task {
                                        try? await Task.sleep(for: .seconds(0.4))
                                        avatarBounce = nil
                                    }
                                } label: {
                                    Text(avatar.emoji)
                                        .font(.system(size: 48))
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
                                        .scaleEffect(avatarBounce == avatar.id ? 1.15 : (selectedAvatar == avatar.id ? 1.05 : 1.0))
                                        .rotationEffect(avatarBounce == avatar.id ? .degrees(-5) : .degrees(0))
                                }
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text(L.s(.mathPractice))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.black)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            ForEach(MathOperation.allCases, id: \.self) { op in
                                let isSelected = selectedOperations.contains(op)
                                let isRecommended = MathOperation.recommended(for: age).contains(op)
                                Button {
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        if isSelected && selectedOperations.count > 1 {
                                            selectedOperations.remove(op)
                                        } else {
                                            selectedOperations.insert(op)
                                        }
                                    }
                                } label: {
                                    Text(op.symbol)
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : GeniColor.border)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(isSelected ? GeniColor.cyan : GeniColor.card)
                                    .overlay(
                                        Rectangle()
                                            .stroke(GeniColor.border, lineWidth: isSelected ? 4 : 2)
                                    )
                                    .background(
                                        isSelected ? AnyView(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3)) : AnyView(EmptyView())
                                    )
                                    .opacity(isRecommended || isSelected ? 1.0 : 0.5)
                                    .scaleEffect(isSelected ? 1.02 : 1.0)
                                }
                            }
                        }

                        if selectedOperations == Set(MathOperation.recommended(for: age)) {
                            Text("⭐ \(L.s(.recommendedForAge))")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.black)
                        }
                    }

                    }
                    .padding(.horizontal, 24)
                }

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
                            Text("▶️")
                                .font(.system(size: 16))
                        }
                    }
                    .buttonStyle(BrutalistButton(color: GeniColor.green))
                    .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(nickname.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
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
