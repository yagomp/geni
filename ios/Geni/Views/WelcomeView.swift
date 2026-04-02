import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false
    @State private var mascotBob = false
    @State private var mascotTilt = false
    @State private var mascotTapped = false
    private let heroBackground = Color(red: 1.0, green: 247 / 255, blue: 224 / 255)

    var body: some View {
        ZStack {
            heroBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image("HeroMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iPadScale.value(290))
                        .scaleEffect(appeared ? (mascotTapped ? 1.18 : 1.0) : 0.3)
                        .rotationEffect(.degrees(mascotTilt ? 4 : -4))
                        .offset(y: mascotBob ? -10 : 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: mascotBob)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: mascotTilt)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: mascotTapped)
                        .onTapGesture {
                            mascotTapped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                mascotTapped = false
                            }
                        }

                    Text(L.s(.appName))
                        .font(.system(size: iPadScale.value(56), weight: .black, design: .rounded))
                        .foregroundStyle(.black)
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
                        Text("▶️")
                            .font(.system(size: 16))
                    }
                }
                .buttonStyle(BrutalistButton(color: .white, textColor: .black))
                .padding(.horizontal, iPadScale.largePadding)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.8), value: appeared)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            appeared = true
            mascotBob = true
            mascotTilt = true
        }
    }
}
