import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    @State private var appeared = false
    @State private var cheers = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let heroBackground = Color(red: 1.0, green: 247 / 255, blue: 224 / 255)

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    // The clips frame Geni a little looser than the old still did; 1.04 keeps Geni the same size.
                    let height = min(iPadScale.value(440), geo.size.height * 0.56) * 1.04
                    Group {
                        if reduceMotion {
                            Image("HeroMascot")
                                .resizable()
                                .scaledToFit()
                        } else {
                            MascotVideoView(cheers: cheers)
                        }
                    }
                    .frame(width: height * MascotVideoView.aspectRatio, height: height)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)
                    .contentShape(Rectangle())
                    .onTapGesture { cheers += 1 }
                    .accessibilityHidden(true)

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
            #if DEBUG
            // Demo recordings: `-mascotDemoCheerAfter 8` cheers 8 s after the screen appears.
            let demoCheer = UserDefaults.standard.double(forKey: "mascotDemoCheerAfter")
            if demoCheer > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + demoCheer) { cheers += 1 }
            }
            #endif
        }
    }
}
