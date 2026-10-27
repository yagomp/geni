import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false
    @State private var mascotBob = false
    @State private var mascotTilt = false
    @State private var mascotTapped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let heroBackground = Color(red: 1.0, green: 247 / 255, blue: 224 / 255)

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image("HeroMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(height: min(iPadScale.value(440), geo.size.height * 0.56))
                        .scaleEffect(appeared ? (mascotTapped ? 1.18 : 1.0) : (reduceMotion ? 1 : 0.3))
                        .rotationEffect(.degrees(reduceMotion ? 0 : (mascotTilt ? 4 : -4)))
                        .offset(y: reduceMotion ? 0 : (mascotBob ? -10 : 8))
                        .opacity(appeared ? 1 : 0)
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
                        .offset(y: appeared || reduceMotion ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
                }

                Spacer()

                Button {
                    HapticManager.impact(.medium)
                    onGetStarted()
                } label: {
                    HStack(spacing: 10) {
                        Text(L.s(.letsPlay))
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .black))
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(BrutalistButton(color: .white, textColor: .black))
                .accessibilityIdentifier("welcome.start")
                .frame(maxWidth: 560)
                .padding(.horizontal, iPadScale.padding)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.8), value: appeared)
            }
            .frame(maxWidth: .infinity)
        }
        .background(heroBackground.ignoresSafeArea())
        .onAppear {
            appeared = true
            guard !reduceMotion else { return }
            mascotBob = true
            mascotTilt = true
        }
    }
}
