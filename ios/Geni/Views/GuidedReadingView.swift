import SwiftUI

struct GuidedReadingView: View {
    let readingVM: ReadingViewModel
    let onComplete: (ReadingSession) -> Void
    let onExit: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                readingHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer().frame(height: 24)

                ScrollView {
                    VStack(spacing: 24) {
                        Text(readingVM.readingText.title)
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundStyle(GeniColor.border)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(readingVM.attributedContent)
                            .font(.system(size: readingFontSize, weight: .bold, design: .rounded))
                            .lineSpacing(readingLineSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.easeInOut(duration: 0.15), value: readingVM.currentWordIndex)
                            .animation(.easeInOut(duration: 0.15), value: readingVM.matchedWordCount)

                        if readingVM.showFeedback {
                            feedbackBanner
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 24)
                }

                readingControls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            appeared = true
            readingVM.start()
        }
        .onDisappear {
            readingVM.stop()
        }
        .onChange(of: readingVM.isCompleted) { _, completed in
            if completed {
                onComplete(readingVM.session)
            }
        }
    }

    private var readingFontSize: CGFloat {
        switch readingVM.profile.ageGroup {
        case .young: return 28
        case .middle: return 24
        case .older: return 20
        }
    }

    private var readingLineSpacing: CGFloat {
        switch readingVM.profile.ageGroup {
        case .young: return 16
        case .middle: return 12
        case .older: return 10
        }
    }

    private var readingHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    HapticManager.selection()
                    readingVM.stop()
                    onExit()
                } label: {
                    Text("◀️").font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(GeniColor.card)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                }

                Spacer()

                modeIndicator

                Spacer()

                HStack(spacing: 4) {
                    Text("🕐")
                        .foregroundStyle(GeniColor.green)
                    Text("\(readingVM.formattedElapsed)/\(readingVM.formattedTarget)")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GeniColor.card)
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)

                    Rectangle()
                        .fill(GeniColor.green)
                        .frame(width: geo.size.width * readingVM.progress, height: 14)
                        .animation(.spring, value: readingVM.progress)
                }
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            }
            .frame(height: 14)
        }
    }

    private var modeIndicator: some View {
        HStack(spacing: 4) {
            Text(modeIcon)
            Text(modeLabel)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.border)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(modeColor.opacity(0.15))
        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))
    }

    private var modeIcon: String {
        switch readingVM.mode {
        case .readByMyself: return "👁️"
        case .readToMe: return "🔊"
        case .listenToMeRead: return "🎤"
        }
    }

    private var modeColor: Color {
        switch readingVM.mode {
        case .readByMyself: return GeniColor.blue
        case .readToMe: return GeniColor.purple
        case .listenToMeRead: return GeniColor.orange
        }
    }

    private var modeLabel: String {
        switch readingVM.mode {
        case .readByMyself: return L.s(.readByMyself)
        case .readToMe: return L.s(.readToMe)
        case .listenToMeRead: return L.s(.listenToMeRead)
        }
    }

    private var readingControls: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.selection()
                readingVM.restart()
            } label: {
                Text("🔄").font(.system(size: 20))
                    .frame(width: 52, height: 52)
                    .background(GeniColor.card)
                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                    .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
            }

            Button {
                HapticManager.impact(.medium)
                if readingVM.isPlaying {
                    readingVM.pause()
                } else {
                    readingVM.resume()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(readingVM.isPlaying ? "⏸️" : "▶️")
                        .font(.title3)
                    Text(readingVM.isPlaying ? L.s(.pause) : L.s(.play))
                        .font(.system(.headline, design: .rounded, weight: .black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GeniColor.green)
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
            }

            if readingVM.mode != .listenToMeRead && readingVM.currentWordIndex >= readingVM.words.count / 2 {
                Button {
                    HapticManager.impact(.heavy)
                    readingVM.completeReading()
                } label: {
                    Text("✓")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(GeniColor.blue)
                        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                        .background(Rectangle().fill(GeniColor.border).offset(x: 3, y: 3))
                }
            }
        }
    }

    private var feedbackBanner: some View {
        HStack(spacing: 12) {
            Text("✨")
                .font(.title2)

            Text(readingVM.feedbackMessage)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(16)
        .background(GeniColor.green)
        .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
        .background(Rectangle().fill(GeniColor.border).offset(x: 4, y: 4))
    }
}
