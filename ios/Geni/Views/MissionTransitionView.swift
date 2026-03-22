import SwiftUI

struct MissionTransitionView: View {
    let mathStars: Int
    let mathCoins: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var showButton = false
    @State private var checkBounce = 0

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(GeniColor.green)
                    .symbolEffect(.bounce, value: checkBounce)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.3)

                VStack(spacing: 8) {
                    Text(L.s(.greatJobMath))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(GeniColor.border)

                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= mathStars ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundStyle(star <= mathStars ? GeniColor.yellow : .gray.opacity(0.3))
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(GeniColor.yellow)
                        Text("+\(mathCoins)")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(GeniColor.border)
                    }
                    .padding(.top, 4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                VStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(GeniColor.green)

                    Text(L.s(.nowLetsRead))
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .brutalistCard(color: GeniColor.green.opacity(0.08))
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)

                Spacer()

                Button {
                    HapticManager.impact(.medium)
                    onContinue()
                } label: {
                    HStack(spacing: 10) {
                        Text(L.s(.continueToReading))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrutalistButton(color: GeniColor.green))
                .padding(.horizontal, 20)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
        .animation(.spring(response: 0.5).delay(0.5), value: showButton)
        .onAppear {
            appeared = true
            HapticManager.notification(.success)
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                checkBounce += 1
                try? await Task.sleep(for: .seconds(0.5))
                showButton = true
            }
        }
    }
}
