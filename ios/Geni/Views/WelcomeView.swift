import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.yellow.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("\u{1F9E0}")
                        .font(.system(size: 56))
                        .frame(width: 120, height: 120)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 4)
                        )
                        .background(
                            Rectangle()
                                .fill(GeniColor.border)
                                .offset(x: 6, y: 6)
                        )
                        .scaleEffect(appeared ? 1.0 : 0.3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

                    Text(L.s(.appName))
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                    Text(L.s(.welcomeSubtitle))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.4), value: appeared)
                }

                Spacer()

                Spacer()

                Button {
                    HapticManager.impact(.medium)
                    onGetStarted()
                } label: {
                    HStack(spacing: 10) {
                        Text(L.s(.createMyGeni))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(BrutalistButton(color: GeniColor.pink))
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.8), value: appeared)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            appeared = true
        }
    }
}
