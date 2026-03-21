import SwiftUI

struct ProfilePickerView: View {
    let profiles: [ChildProfile]
    let onSelect: (ChildProfile) -> Void
    let onAddProfile: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Text(L.s(.selectProfile))
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 20)], spacing: 20) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        let avatar = AvatarOption.find(profile.avatarId)
                        Button {
                            HapticManager.impact(.medium)
                            onSelect(profile)
                        } label: {
                            VStack(spacing: 12) {
                                Text(avatar.emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 80, height: 80)
                                    .background(.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(GeniColor.border, lineWidth: 3)
                                    )
                                    .background(
                                        Rectangle()
                                            .fill(GeniColor.border)
                                            .offset(x: 4, y: 4)
                                    )

                                Text(profile.nickname)
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(GeniColor.border)

                                Text("\(profile.age) \(L.s(.age).lowercased())")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .brutalistCard(color: GeniColor.card)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: appeared)
                    }

                    Button {
                        HapticManager.selection()
                        onAddProfile()
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(GeniColor.blue)
                                .frame(width: 80, height: 80)
                                .background(GeniColor.blue.opacity(0.1))
                                .overlay(
                                    Rectangle()
                                        .stroke(GeniColor.border, lineWidth: 3)
                                )

                            Text(L.s(.addProfile))
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(GeniColor.border)

                            Text(" ")
                                .font(.system(.caption, design: .rounded))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .brutalistCard(color: GeniColor.card, borderWidth: 2)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(Double(profiles.count) * 0.1), value: appeared)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { appeared = true }
    }
}
