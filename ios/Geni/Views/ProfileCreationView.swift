import SwiftUI

struct ProfileCreationView: View {
    let onComplete: (ChildProfile) -> Void
    var editingProfile: ChildProfile? = nil
    var onBack: (() -> Void)? = nil

    private var bgColor: Color {
        switch selectedTheme {
        case .standard: return editingProfile != nil ? GeniColor.background : Color(red: 1.0, green: 0.97, blue: 0.88)
        case .ocean: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.93, blue: 0.95)
        }
    }

    @State private var nickname: String = ""
    @State private var age: Int = 6
    @State private var selectedAvatar: String = "lion"
    @State private var selectedOperations: Set<MathOperation> = Set(MathOperation.recommended(for: 6))
    @State private var selectedTheme: AppTheme = .standard
    @State private var avatarBounce: String? = nil
    @State private var showFullAvatarPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                    HStack {
                        if let onBack {
                            Button {
                                HapticManager.selection()
                                if var existing = editingProfile {
                                    existing.nickname = nickname
                                    existing.age = age
                                    existing.avatarId = selectedAvatar
                                    existing.operationsEnabled = Array(selectedOperations)
                                    existing.theme = selectedTheme
                                    ThemeManager.shared.current = selectedTheme
                                    onComplete(existing)
                                } else {
                                    onBack()
                                }
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

                        let quickAvatars = Array(AvatarOption.all.prefix(7))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(quickAvatars) { avatar in
                                avatarButton(avatar)
                            }

                            // "More" button in last slot of row 2
                            Button {
                                HapticManager.selection()
                                showFullAvatarPicker = true
                            } label: {
                                Text("···")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(GeniColor.border)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(GeniColor.card)
                                    .overlay(
                                        Rectangle()
                                            .stroke(GeniColor.border, lineWidth: 2)
                                    )
                            }

                            // Show selected avatar inline if it's not in quickAvatars
                            if !quickAvatars.contains(where: { $0.id == selectedAvatar }) {
                                let selected = AvatarOption.find(selectedAvatar)
                                avatarButton(selected)
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Text(L.s(.theme))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                                let isSelected = selectedTheme == theme
                                Button {
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedTheme = theme
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(themeSwatchColor(theme))
                                            .frame(width: 18, height: 18)
                                            .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                        Text(themeDisplayName(theme))
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(GeniColor.border)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(isSelected ? themeSwatchBg(theme) : GeniColor.card)
                                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: isSelected ? 3 : 2))
                                    .background(isSelected ? AnyView(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3)) : AnyView(EmptyView()))
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
                            existing.theme = selectedTheme
                            profile = existing
                        } else {
                            var newProfile = ChildProfile(nickname: nickname, age: age, avatarId: selectedAvatar)
                            newProfile.operationsEnabled = Array(selectedOperations)
                            newProfile.theme = selectedTheme
                            profile = newProfile
                        }
                        ThemeManager.shared.current = selectedTheme
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
                selectedTheme = profile.theme
            }
        }
        .onChange(of: age) { _, newAge in
            selectedOperations = Set(MathOperation.recommended(for: newAge))
        }
        .sheet(isPresented: $showFullAvatarPicker) {
            fullAvatarPicker
        }
    }

    private var fullAvatarPicker: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(AvatarOption.all) { avatar in
                            Button {
                                HapticManager.selection()
                                selectedAvatar = avatar.id
                                showFullAvatarPicker = false
                            } label: {
                                Text(avatar.emoji)
                                    .font(.system(size: 40))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(selectedAvatar == avatar.id ? avatar.color.opacity(0.2) : .white)
                                    .overlay(Rectangle().stroke(selectedAvatar == avatar.id ? avatar.color : GeniColor.border, lineWidth: selectedAvatar == avatar.id ? 4 : 2))
                            }
                        }

                        ForEach(AvatarOption.extras) { avatar in
                            Button {
                                HapticManager.selection()
                                selectedAvatar = avatar.id
                                showFullAvatarPicker = false
                            } label: {
                                Text(avatar.emoji)
                                    .font(.system(size: 40))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(selectedAvatar == avatar.id ? avatar.color.opacity(0.2) : .white)
                                    .overlay(Rectangle().stroke(selectedAvatar == avatar.id ? avatar.color : GeniColor.border, lineWidth: selectedAvatar == avatar.id ? 4 : 2))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(bgColor.ignoresSafeArea())
            .safeAreaInset(edge: .top) {
                HStack {
                    Text(L.s(.chooseAvatar))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(.black)
                    Spacer()
                    Button {
                        showFullAvatarPicker = false
                    } label: {
                        Text("✕")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 32, height: 32)
                            .background(GeniColor.card)
                            .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(bgColor)
            }
        }
        .presentationDetents([.medium])
    }

    private func avatarButton(_ avatar: AvatarOption) -> some View {
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

    private func themeSwatchColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return Color(red: 1.0, green: 0.84, blue: 0.04)
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }

    private func themeSwatchBg(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return Color(red: 1.0, green: 0.97, blue: 0.88)
        case .ocean: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.93, blue: 0.95)
        }
    }

    private func themeDisplayName(_ theme: AppTheme) -> String {
        switch theme {
        case .standard: return L.s(.themeStandard)
        case .ocean: return L.s(.themeOcean)
        case .blossom: return L.s(.themeBlossom)
        }
    }
}
