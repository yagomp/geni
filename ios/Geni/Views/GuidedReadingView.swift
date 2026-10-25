import SwiftUI

struct GuidedReadingView: View {
    let readingVM: ReadingViewModel
    let onComplete: (ReadingSession) -> Void
    let onExit: () -> Void

    var body: some View {
        GeniLearningLayout {
            GuidedReadingViewLayout(readingVM: readingVM, onComplete: onComplete, onExit: onExit)
        }
    }
}

private struct GuidedReadingViewLayout: View {
    @Environment(\.geniExpandedLayout) private var expanded
    let readingVM: ReadingViewModel
    let onComplete: (ReadingSession) -> Void
    let onExit: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                readingHeader
                    .padding(.horizontal, expanded ? 40 : 20)
                    .padding(.top, expanded ? 28 : 20)

                Spacer().frame(height: expanded ? 32 : 24)

                if expanded {
                    GeometryReader { remaining in
                        ScrollView {
                            passage
                                .padding(36)
                                .frame(maxWidth: .infinity, minHeight: max(0, remaining.size.height - 12), alignment: .topLeading)
                                .brutalistCard(color: GeniColor.card)
                                .padding(.bottom, 8)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        passage
                            .padding(.horizontal, 24)
                    }
                }

                readingControls
                    .padding(.horizontal, expanded ? 40 : 20)
                    .padding(.top, expanded ? 28 : 0)
                    .padding(.bottom, expanded ? 28 : 20)
            }
            .frame(maxWidth: expanded ? 1040 : .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var passage: some View {
        VStack(alignment: .leading, spacing: expanded ? 32 : 24) {
            Text(readingVM.readingText.title)
                .font(.system(expanded ? .largeTitle : .title3, design: .rounded, weight: .black))
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
            if !expanded { Spacer().frame(height: 80) }
        }
    }

    private var readingFontSize: CGFloat {
        if expanded {
            switch readingVM.profile.ageGroup {
            case .young: return 40
            case .middle: return 38
            case .older: return 34
            }
        }
        switch readingVM.profile.ageGroup {
        case .young: return 28
        case .middle: return 24
        case .older: return 20
        }
    }

    private var readingLineSpacing: CGFloat {
        if expanded { return 18 }
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
                    Text("◀️").font(.system(size: expanded ? 28 : 20))
                        .frame(width: expanded ? 64 : 44, height: expanded ? 64 : 44)
                        .background(GeniColor.card)
                        .clipShape(GeniShape())
                        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                }
                .accessibilityIdentifier("reading.back")

                Spacer()

                modeIndicator

                Spacer()

                HStack(spacing: 4) {
                    Text("🕐")
                        .foregroundStyle(GeniColor.green)
                    Text("\(readingVM.formattedElapsed)/\(readingVM.formattedTarget)")
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                        .foregroundStyle(GeniColor.border)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GeniColor.card)
                .clipShape(GeniShape())
                .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                .background(GeniShape().fill(GeniColor.border).offset(x: 3, y: 3))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    GeniShape()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: expanded ? 20 : 14)

                    Rectangle()
                        .fill(GeniColor.green)
                        .frame(width: geo.size.width * readingVM.progress, height: expanded ? 20 : 14)
                        .animation(.spring, value: readingVM.progress)
                }
                .clipShape(GeniShape())
                .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
            }
            .frame(height: expanded ? 20 : 14)
        }
    }

    private var modeIndicator: some View {
        HStack(spacing: 4) {
            Text(modeIcon)
            Text(modeLabel)
                .font(.system(expanded ? .title3 : .caption, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.border)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(modeColor.soft(0.2))
        .clipShape(GeniShape())
        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 2))
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
                Text("🔄").font(.system(size: expanded ? 28 : 20))
                    .frame(width: expanded ? 80 : 52, height: expanded ? 80 : 52)
                    .background(GeniColor.card)
                    .clipShape(GeniShape())
                    .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                    .background(GeniShape().fill(GeniColor.border).offset(x: 3, y: 3))
            }
            .accessibilityIdentifier("reading.restart")

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
                        .font(expanded ? .largeTitle : .title3)
                    Text(readingVM.isPlaying ? L.s(.pause) : L.s(.play))
                        .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: expanded ? 80 : 52)
                .background(GeniColor.green)
                .clipShape(GeniShape())
                .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                .background(GeniShape().fill(GeniColor.border).offset(x: 4, y: 4))
            }
            .accessibilityIdentifier("reading.playPause")

            if readingVM.mode == .listenToMeRead {
                Button {
                    HapticManager.selection()
                    readingVM.skipCurrentListenWord()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(readingVM.isPlaying ? GeniColor.border : Color(white: 0.55))
                        .frame(width: expanded ? 80 : 52, height: expanded ? 80 : 52)
                        .background(readingVM.isPlaying ? GeniColor.orange : GeniColor.lightGray)
                        .clipShape(GeniShape())
                        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                        .background(GeniShape().fill(GeniColor.border).offset(x: 3, y: 3))
                }
                .accessibilityLabel(L.s(.next))
                .accessibilityIdentifier("reading.skip")
                .disabled(!readingVM.isPlaying)
            }

            if readingVM.mode != .listenToMeRead && readingVM.currentWordIndex >= readingVM.words.count / 2 {
                Button {
                    HapticManager.impact(.heavy)
                    readingVM.completeReading()
                } label: {
                    Text("✓")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: expanded ? 80 : 52, height: expanded ? 80 : 52)
                        .background(GeniColor.blue)
                        .clipShape(GeniShape())
                        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
                        .background(GeniShape().fill(GeniColor.border).offset(x: 3, y: 3))
                }
                .accessibilityIdentifier("reading.finish")
            }
        }
    }

    private var feedbackBanner: some View {
        HStack(spacing: 12) {
            Text("✨")
                .font(.title2)

            Text(readingVM.feedbackMessage)
                .font(.system(expanded ? .title2 : .headline, design: .rounded, weight: .bold))
                .foregroundStyle(feedbackColor.readableText)
                .accessibilityIdentifier("reading.feedback")

            Spacer()
        }
        .padding(16)
        .background(feedbackColor)
        .clipShape(GeniShape())
        .overlay(GeniShape().stroke(GeniColor.border, lineWidth: 3))
        .background(GeniShape().fill(GeniColor.border).offset(x: 4, y: 4))
        .compositingGroup()
    }

    private var feedbackColor: Color {
        switch readingVM.feedbackTone {
        case .success:
            GeniColor.green
        case .guidance:
            GeniColor.orange
        case .error:
            GeniColor.pink
        }
    }
}
