import SwiftUI
import SafariServices
import StoreKit

struct ParentDashboardView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var pinVerified = false
    @State private var showPinEntry = true
    @State private var pinInput = ""
    @State private var pinError = false
    @State private var showProfileCreation = false
    @State private var editingProfile: ChildProfile? = nil
    @State private var newPin = ""
    @State private var showSetPin = false
    @State private var showDisablePin = false
    @State private var selectedLanguage: AppLanguage = L.selectedLanguage
    @State private var languageManager = LanguageManager.shared
    @State private var showContactSheet = false
    @State private var confirmStartOver = false
    @AppStorage(HapticManager.enabledKey) private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            if viewModel.persistence.parentPin != nil && !pinVerified {
                pinEntryView
            } else {
                settingsContent
            }
        }
    }

    private var pinEntryView: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button {
                        HapticManager.selection()
                        dismiss()
                    } label: {
                        Text("◀️").font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .softSurface(GeniColor.card)
                    }
                    Spacer()
                }

                Text("🔒")
                    .font(.system(size: 48))
                    .foregroundStyle(GeniColor.blue)

                Text(L.s(.parentArea))
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(.black)

                Text(L.s(.pinRequired))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.black)

                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { i in
                        GeniShape(scale: 0.5)
                            .fill(i < pinInput.count ? GeniColor.blue : Color.gray.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                GeniShape(scale: 0.5)
                                    .stroke(GeniColor.hairline, lineWidth: 1)
                            )
                    }
                }

                if pinError {
                    Text(L.s(.wrongPin))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(GeniColor.pink)
                }

                pinPad(input: $pinInput) { pin in
                    if viewModel.persistence.verifyPin(pin) {
                        pinVerified = true
                        HapticManager.notification(.success)
                    } else {
                        pinError = true
                        pinInput = ""
                        HapticManager.notification(.error)
                    }
                }
            }
            .padding(iPadScale.padding)
        }
        .buttonStyle(KidPressStyle())
        .navigationBarHidden(true)
    }

    private var settingsContent: some View {
        ZStack {
            GeniColor.lightYellow.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button {
                            HapticManager.selection()
                            dismiss()
                        } label: {
                            Text("◀️").font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .softSurface(GeniColor.card)
                        }
                        .accessibilityIdentifier("parent.back")

                        Spacer()

                        Text(L.s(.parentSettings))
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundStyle(GeniColor.border)
                            .accessibilityIdentifier("parent.title")

                        Spacer()

                        Color.clear.frame(width: 44, height: 44)
                    }

                    profilesSection
                    languageSection
                    progressOverviewSection
                        #if DEBUG
                        .id("designPreview.parentProgress")
                        #endif
                    reminderSection
                    vibrationSection
                    iCloudSyncSection
                    contactSection
                    rateGeniRow
                    pinSection
                    startOverButton
                }
                .padding(iPadScale.padding)
                .foregroundStyle(.black)
            }
            #if DEBUG
            .designPreviewParentScroll()
            #endif
        }
        .buttonStyle(KidPressStyle())
        .navigationBarHidden(true)
        .sheet(isPresented: $showContactSheet) {
            SafariView(url: URL(string: "https://geni.kids/contact.html")!)
                .ignoresSafeArea()
        }
        // This content only appears after the optional parent PIN is verified.
        .onAppear(perform: requestReviewIfEligible)
        .fullScreenCover(isPresented: $showProfileCreation) {
            ProfileCreationView(onComplete: { profile in
                viewModel.saveProfile(profile)
                showProfileCreation = false
            }, existingNames: viewModel.persistence.profiles.map(\.nickname), onBack: {
                showProfileCreation = false
            })
        }
        .fullScreenCover(item: $editingProfile) { profile in
            ProfileCreationView(onComplete: { updated in
                viewModel.saveProfile(updated)
                editingProfile = nil
            }, existingNames: viewModel.persistence.profiles.filter { $0.id != profile.id }.map(\.nickname), editingProfile: profile, onBack: {
                editingProfile = nil
            })
        }
    }

    private func requestReviewIfEligible() {
        let process = ProcessInfo.processInfo
        let defaults = UserDefaults.standard
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let now = Date()
        let totalChapters = viewModel.persistence.profiles.reduce(0) { total, profile in
            total + viewModel.persistence.loadRewardState(for: profile.id).totalChaptersCompleted
        }
        guard ReviewPrompt.shouldRequest(
            totalChaptersCompleted: totalChapters,
            lastRequest: defaults.object(forKey: ReviewPrompt.lastRequestKey) as? Date,
            lastRequestedVersion: defaults.string(forKey: ReviewPrompt.requestedVersionKey),
            currentVersion: version,
            now: now,
            arguments: process.arguments,
            environment: process.environment
        ) else { return }

        // Store attempts even when StoreKit chooses not to display its prompt.
        defaults.set(now, forKey: ReviewPrompt.lastRequestKey)
        defaults.set(version, forKey: ReviewPrompt.requestedVersionKey)
        requestReview()
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.theme))
                .font(.system(.headline, design: .rounded, weight: .bold))

            HStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    let isSelected = viewModel.persistence.activeProfile?.theme == theme
                    Button {
                        HapticManager.selection()
                        guard var profile = viewModel.persistence.activeProfile else { return }
                        profile.theme = theme
                        viewModel.saveProfile(profile)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                GeniShape()
                                    .fill(themePreviewBg(theme))
                                    .frame(height: 56)
                                    .overlay(GeniShape().stroke(GeniColor.hairline, lineWidth: 1))

                                HStack(spacing: 6) {
                                    Circle().fill(themePreviewAccent(theme)).frame(width: 14, height: 14)
                                    GeniShape(scale: 0.5)
                                        .fill(themePreviewCard(theme))
                                        .frame(width: 28, height: 14)
                                        .overlay(GeniShape(scale: 0.5).stroke(GeniColor.hairline, lineWidth: 1))
                                    Circle().fill(themePreviewSecondary(theme)).frame(width: 14, height: 14)
                                }
                            }

                            Text(themeLabel(theme))
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(GeniColor.border)

                            if isSelected {
                                Text("✅")
                                    .font(.system(size: 14))
                            } else {
                                Text(" ")
                                    .font(.system(size: 14))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .softSurface(isSelected ? themePreviewBg(theme).soft(0.3) : GeniColor.card)
                    }
                }
            }
        }
    }

    private func themePreviewBg(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return Color(red: 1.0, green: 0.97, blue: 0.88)
        case .ocean: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.93, blue: 0.95)
        }
    }

    private func themePreviewCard(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return .white
        case .ocean: return Color(red: 0.95, green: 0.97, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.97, blue: 0.98)
        }
    }

    private func themePreviewAccent(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return Color(red: 0.0, green: 0.4, blue: 1.0)
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }

    private func themePreviewSecondary(_ theme: AppTheme) -> Color {
        switch theme {
        case .standard: return Color(red: 1.0, green: 0.84, blue: 0.04)
        case .ocean: return Color(red: 0.4, green: 0.85, blue: 0.95)
        case .blossom: return Color(red: 0.85, green: 0.55, blue: 0.75)
        }
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .standard: return L.s(.themeStandard)
        case .ocean: return L.s(.themeOcean)
        case .blossom: return L.s(.themeBlossom)
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.language))
                .font(.system(.headline, design: .rounded, weight: .bold))

            ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                let isSelected = selectedLanguage == lang
                Button {
                    HapticManager.selection()
                    selectedLanguage = lang
                    L.selectedLanguage = lang
                    languageManager.current = lang
                } label: {
                    HStack(spacing: 12) {
                        Text(lang.flag)
                            .font(.system(size: 24))
                            .frame(width: 40)

                        Text(languageLabel(lang))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(GeniColor.border)

                        Spacer()

                        if isSelected {
                            Text("✅")
                                .font(.system(size: 18))
                        }
                    }
                    .padding(12)
                    .softSurface(GeniColor.card)
                }
            }
        }
    }

    private func languageLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return L.s(.languageEnglish)
        case .norwegian: return L.s(.languageNorwegian)
        case .spanish: return L.s(.languageSpanish)
        case .portuguese: return L.s(.languagePortuguese)
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.profiles))
                .font(.system(.headline, design: .rounded, weight: .bold))

            ForEach(viewModel.persistence.profiles) { profile in
                let avatar = AvatarOption.find(profile.avatarId)
                HStack(spacing: 12) {
                    Text(avatar.emoji)
                        .font(.system(size: 32))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.nickname)
                            .font(.system(.body, design: .rounded, weight: .bold))
                        Text("\(L.s(.age)): \(profile.age)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.black)
                    }

                    Spacer()

                    Button {
                        HapticManager.selection()
                        editingProfile = profile
                    } label: {
                        Text("✏️")
                            .font(.system(size: 18))
                    }
                    .accessibilityIdentifier("parent.edit.\(profile.nickname)")

                    if viewModel.persistence.profiles.count > 1 {
                        Button {
                            HapticManager.selection()
                            viewModel.deleteProfile(profile.id)
                        } label: {
                            Text("🗑️")
                                .font(.system(size: 18))
                        }
                        .accessibilityIdentifier("parent.delete.\(profile.nickname)")
                    }
                }
                .padding(12)
                .softSurface(GeniColor.card)
            }

            Button {
                HapticManager.selection()
                showProfileCreation = true
            } label: {
                HStack {
                    Text("➕")
                    Text(L.s(.addProfile))
                }
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(GeniColor.blue)
            }
            .accessibilityIdentifier("parent.add")
        }
    }

    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.progress))
                .font(.system(.headline, design: .rounded, weight: .bold))

            ForEach(viewModel.persistence.profiles) { profile in
                let avatar = AvatarOption.find(profile.avatarId)
                let rewards = viewModel.persistence.loadRewardState(for: profile.id)
                let chapters = viewModel.persistence.loadAllChapters(for: profile.id)
                let completedChapters = chapters.filter { $0.status == .completed }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text(avatar.emoji)
                            .font(.system(size: 28))
                            .frame(width: 36, height: 36)

                        Text(profile.nickname)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(GeniColor.border)

                        Spacer()

                        Text("\(L.s(.level)) \(rewards.level)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(GeniColor.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(GeniColor.purple.opacity(0.1))
                            .clipShape(GeniShape(scale: 0.5))
                            .overlay(
                                GeniShape(scale: 0.5)
                                    .stroke(GeniColor.purple.opacity(0.3), lineWidth: 2)
                                    .allowsHitTesting(false)
                            )
                    }

                    ParentChildInsights(
                        viewModel: viewModel, profile: profile,
                        chapters: chapters, rewards: rewards
                    )

                    if !completedChapters.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.s(.recentChapters))
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.black)
                                .textCase(.uppercase)

                            let recent = completedChapters.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }.prefix(5)
                            ForEach(Array(recent)) { ch in
                                HStack(spacing: 8) {
                                    Text(chapterTypeEmoji(ch.chapterType))
                                        .font(.system(size: 12))
                                        .frame(width: 20)

                                    Text(chapterDateLabel(ch.date))
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundStyle(GeniColor.border)

                                    if ch.chapterType != .daily {
                                        Text(chapterTypeName(ch.chapterType))
                                            .font(.system(.caption2, design: .rounded, weight: .bold))
                                            .foregroundStyle(chapterTypeColor(ch.chapterType))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(chapterTypeColor(ch.chapterType).opacity(0.1))
                                            .clipShape(GeniShape(scale: 0.5))
                                            .overlay(
                                                GeniShape(scale: 0.5)
                                                    .stroke(chapterTypeColor(ch.chapterType).opacity(0.3), lineWidth: 1)
                                                    .allowsHitTesting(false)
                                            )
                                    }

                                    Spacer()

                                    HStack(spacing: 1) {
                                        ForEach(0..<5, id: \.self) { i in
                                            Text(i < ch.stars ? "⭐" : "☆")
                                                .font(.system(size: 10))
                                                .foregroundStyle(i < ch.stars ? .primary : Color.gray.opacity(0.3))
                                        }
                                    }

                                    Text("\(ch.correctCount)/\(ch.completedExerciseCount)")
                                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        Text(L.s(.noChaptersYet))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(12)
                .softSurface(GeniColor.card)
            }
        }
    }

    private func chapterTypeEmoji(_ type: ChapterType) -> String {
        switch type {
        case .daily: return "📘"
        case .timeAttack: return "⏱️"
        case .perfectRun: return "👑"
        case .boss: return "🛡️"
        case .streak: return "🔥"
        case .operationSpotlight: return "🔍"
        }
    }

    private func chapterTypeColor(_ type: ChapterType) -> Color {
        switch type {
        case .daily: return GeniColor.blue
        case .timeAttack: return GeniColor.orange
        case .perfectRun: return GeniColor.purple
        case .boss: return GeniColor.pink
        case .streak: return GeniColor.orange
        case .operationSpotlight: return GeniColor.cyan
        }
    }

    private func chapterTypeName(_ type: ChapterType) -> String {
        switch type {
        case .daily: return L.s(.dailyChapter)
        case .timeAttack: return L.s(.timeAttack)
        case .perfectRun: return L.s(.perfectRun)
        case .boss: return L.s(.bossChapter)
        case .streak: return L.s(.streakBonus)
        case .operationSpotlight: return L.s(.spotlightChapter)
        }
    }

    private func chapterDateLabel(_ dateStr: String) -> String {
        let today = viewModel.persistence.todayString()
        if dateStr == today { return L.s(.today) }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        if let date = fmt.date(from: dateStr) {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let yesterdayStr = fmt.string(from: yesterday)
            if dateStr == yesterdayStr { return L.s(.yesterday) }

            let display = DateFormatter()
            display.dateStyle = .short
            return display.string(from: date)
        }
        return dateStr
    }

    private var vibrationSection: some View {
        Toggle(isOn: $hapticsEnabled) {
            Text(L.t("Vibration", no: "Vibrasjon", es: "Vibración", pt: "Vibração"))
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .tint(GeniColor.blue)
        .padding(12)
        .softSurface(GeniColor.card)
        .accessibilityIdentifier("parent.vibration")
        .onChange(of: hapticsEnabled) { _, enabled in
            HapticManager.isEnabled = enabled
            if enabled { HapticManager.selection() }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.reminders))
                .font(.system(.headline, design: .rounded, weight: .bold))

            HStack {
                Text("🔔")
.font(.system(size: 22))
                    .frame(width: 40)

                Text(L.s(.dailyReminder))
                    .font(.system(.body, design: .rounded, weight: .semibold))

                Spacer()

                Button {
                    HapticManager.selection()
                    if viewModel.notificationService.isEnabled {
                        viewModel.notificationService.disableReminders()
                    } else {
                        viewModel.notificationService.enableReminders()
                    }
                } label: {
                    Text(viewModel.notificationService.isEnabled ? "✅" : "⬜")
                        .font(.system(size: 28))
                }
            }
            .padding(12)
            .softSurface(GeniColor.card)

            if viewModel.notificationService.isEnabled {
                HStack {
                    Text("🕐")
.font(.system(size: 22))
                        .frame(width: 40)

                    Text(L.s(.reminderTime))
                        .font(.system(.body, design: .rounded, weight: .semibold))

                    Spacer()

                    DatePicker("", selection: Binding(
                        get: {
                            var comps = DateComponents()
                            comps.hour = viewModel.notificationService.reminderHour
                            comps.minute = viewModel.notificationService.reminderMinute
                            return Calendar.current.date(from: comps) ?? Date()
                        },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            viewModel.notificationService.setReminderTime(
                                hour: comps.hour ?? 17,
                                minute: comps.minute ?? 0
                            )
                        }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
                .padding(12)
                .softSurface(GeniColor.card)
            }
        }
    }

    private var iCloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.iCloudSync))
                .font(.system(.headline, design: .rounded, weight: .bold))

            VStack(spacing: 12) {
                HStack {
                    Text("☁️")
                        .font(.system(size: 22))
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.s(.iCloudSync))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        Text(L.s(.iCloudSyncDesc))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.black)
                    }

                    Spacer()

                    Button {
                        HapticManager.selection()
                        viewModel.cloudSync.setSyncEnabled(!viewModel.cloudSync.syncEnabled)
                        if viewModel.cloudSync.syncEnabled {
                            viewModel.cloudSync.pushToCloud(persistence: viewModel.persistence)
                        }
                    } label: {
                        Text(viewModel.cloudSync.syncEnabled ? "✅" : "⬜")
                            .font(.system(size: 28))
                    }
                }

                if !viewModel.cloudSync.isICloudAvailable {
                    Text(L.s(.iCloudNotAvailable))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(GeniColor.orange)
                } else if viewModel.cloudSync.syncEnabled {
                    HStack(spacing: 12) {
                        Button {
                            HapticManager.impact(.medium)
                            viewModel.cloudSync.pushToCloud(persistence: viewModel.persistence)
                        } label: {
                            HStack(spacing: 6) {
                                if viewModel.cloudSync.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("🔄")
                                }
                                Text(L.s(.syncNow))
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                            }
                            .foregroundStyle(GeniColor.blue)
                        }
                        .disabled(viewModel.cloudSync.isSyncing)

                        Spacer()

                        if let lastSync = viewModel.cloudSync.lastSyncDate {
                            Text("\(L.s(.synced)) \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.black)
                        }
                    }
                }

                if let error = viewModel.cloudSync.syncError {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(GeniColor.pink)
                }
            }
            .padding(12)
            .softSurface(GeniColor.card)
        }
    }

    private var pinSection: some View {
        let pinSet = viewModel.persistence.parentPin != nil

        return VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.pin))
                .font(.system(.headline, design: .rounded, weight: .bold))

            Button {
                HapticManager.selection()
                showSetPin = true
            } label: {
                HStack(spacing: 0) {
                    Text(pinSet ? "🔒" : "🔓")
                        .font(.system(size: 22))
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pinSet ? L.s(.changePin) : L.s(.setPin))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.black)

                        Text(L.s(.pinDescription))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.black.opacity(0.5))
                    }

                    Spacer()

                    Circle()
                        .fill(pinSet ? GeniColor.green : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .padding(.trailing, 8)

                    Text("›")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                }
                .padding(12)
                .softSurface(GeniColor.card)
            }

            if pinSet {
                Button {
                    HapticManager.selection()
                    showDisablePin = true
                } label: {
                    HStack(spacing: 0) {
                        Text("🔓")
                            .font(.system(size: 22))
                            .frame(width: 40)

                        Text(L.s(.disablePin))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.red)

                        Spacer()

                        Text("›")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .softSurface(GeniColor.card)
                }
            }
        }
        .sheet(isPresented: $showSetPin) {
            SetPinView { pin in
                viewModel.persistence.setPin(pin)
                showSetPin = false
            }
        }
        .sheet(isPresented: $showDisablePin) {
            if let currentPin = viewModel.persistence.parentPin {
                DisablePinView(currentPin: currentPin) {
                    viewModel.persistence.clearPin()
                    showDisablePin = false
                }
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.contactSupport))
                .font(.system(.headline, design: .rounded, weight: .bold))

            Button {
                HapticManager.selection()
                showContactSheet = true
            } label: {
                HStack(spacing: 12) {
                    Text("✉️")
                        .font(.system(size: 22))
                        .frame(width: 40)

                    Text(L.s(.contactSupport))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.black)

                    Spacer()

                    Text("›")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                }
                .padding(12)
                .softSurface(GeniColor.card)
            }
        }
    }

    private var rateGeniRow: some View {
        Button {
            guard let url = URL(string: "https://apps.apple.com/app/id6761134405?action=write-review") else { return }
            HapticManager.selection()
            openURL(url)
        } label: {
            HStack(spacing: 12) {
                Text("⭐")
                    .font(.system(size: 22))
                    .frame(width: 40)

                Text(L.t("Rate Geni", no: "Gi Geni en vurdering", es: "Valora Geni", pt: "Avalie o Geni"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()

                Text("›")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(12)
            .softSurface(GeniColor.card)
        }
        .accessibilityIdentifier("parent.rateGeni")
    }

    private var startOverButton: some View {
        Button {
            HapticManager.selection()
            confirmStartOver = true
        } label: {
            HStack(spacing: 0) {
                Text("🔄")
                    .font(.system(size: 22))
                    .frame(width: 40)

                Text(L.s(.startOver))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.red)

                Spacer()
            }
            .padding(12)
            .softSurface(GeniColor.card)
        }
        .accessibilityIdentifier("parent.startOver")
        .confirmationDialog(L.s(.startOver), isPresented: $confirmStartOver, titleVisibility: .visible) {
            Button(L.s(.startOver), role: .destructive) {
                HapticManager.impact(.heavy)
                // Let the action sheet finish dismissing before the dashboard itself closes
                Task { @MainActor in viewModel.resetApp() }
            }
            .accessibilityIdentifier("parent.startOver.confirm")
            Button(L.s(.cancel), role: .cancel) {}
        } message: {
            Text(L.s(viewModel.cloudSync.syncEnabled ? .startOverMessage : .startOverMessageLocal))
        }
    }

    private func pinPad(input: Binding<String>, onComplete: @escaping (String) -> Void) -> some View {
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "DEL"]
        ]

        return VStack(spacing: 12) {
            ForEach(numbers, id: \.description) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 72, height: 52)
                        } else {
                            Button {
                                HapticManager.selection()
                                if key == "DEL" {
                                    if !input.wrappedValue.isEmpty {
                                        input.wrappedValue.removeLast()
                                    }
                                } else if input.wrappedValue.count < 4 {
                                    input.wrappedValue += key
                                    pinError = false
                                    if input.wrappedValue.count == 4 {
                                        onComplete(input.wrappedValue)
                                    }
                                }
                            } label: {
                                Group {
                                    if key == "DEL" {
                                        Text("⌫")
                                            .font(.system(.title3, design: .rounded, weight: .bold))
                                    } else {
                                        Text(key)
                                            .font(.system(.title2, design: .rounded, weight: .bold))
                                    }
                                }
                                .foregroundStyle(GeniColor.border)
                                .frame(width: 72, height: 52)
                                .softSurface(GeniColor.card)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct SetPinView: View {
    let onSet: (String) -> Void
    @State private var pin = ""
    @State private var firstPin = ""
    @State private var confirming = false
    @State private var showMismatch = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GeniColor.lightYellow.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(confirming ? L.s(.confirmPin) : L.s(.setPin))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(.black)

                    if showMismatch {
                        Text(L.s(.pinMismatch))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            GeniShape(scale: 0.5)
                                .fill(i < pin.count ? GeniColor.blue : Color.gray.opacity(0.2))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    GeniShape(scale: 0.5)
                                        .stroke(GeniColor.hairline, lineWidth: 1)
                                )
                        }
                    }

                    pinPadView
                        .buttonStyle(KidPressStyle())
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s(.cancel)) { dismiss() }
                }
            }
        }
    }

    private var pinPadView: some View {
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "DEL"]
        ]

        return VStack(spacing: 12) {
            ForEach(numbers, id: \.description) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 72, height: 52)
                        } else {
                            Button {
                                HapticManager.selection()
                                if key == "DEL" {
                                    if !pin.isEmpty { pin.removeLast() }
                                } else if pin.count < 4 {
                                    pin += key
                                    if pin.count == 4 {
                                        if !confirming {
                                            firstPin = pin
                                            pin = ""
                                            confirming = true
                                            showMismatch = false
                                        } else if pin == firstPin {
                                            HapticManager.notification(.success)
                                            onSet(pin)
                                        } else {
                                            HapticManager.notification(.error)
                                            pin = ""
                                            firstPin = ""
                                            confirming = false
                                            showMismatch = true
                                        }
                                    }
                                }
                            } label: {
                                Group {
                                    if key == "DEL" {
                                        Text("⌫")
                                            .font(.system(.title3, design: .rounded, weight: .bold))
                                    } else {
                                        Text(key)
                                            .font(.system(.title2, design: .rounded, weight: .bold))
                                    }
                                }
                                .foregroundStyle(GeniColor.border)
                                .frame(width: 72, height: 52)
                                .softSurface(GeniColor.card)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DisablePinView: View {
    let currentPin: String
    let onDisable: () -> Void
    @State private var pin = ""
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GeniColor.lightYellow.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(L.s(.disablePin))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(.black)

                    if showError {
                        Text(L.s(.wrongPin))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            GeniShape(scale: 0.5)
                                .fill(i < pin.count ? GeniColor.blue : Color.gray.opacity(0.2))
                                .frame(width: 20, height: 20)
                                .overlay(GeniShape(scale: 0.5).stroke(GeniColor.hairline, lineWidth: 1))
                        }
                    }

                    pinPadView
                        .buttonStyle(KidPressStyle())
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s(.cancel)) { dismiss() }
                }
            }
        }
    }

    private var pinPadView: some View {
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "DEL"]
        ]
        return VStack(spacing: 12) {
            ForEach(numbers, id: \.description) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 72, height: 52)
                        } else {
                            Button {
                                HapticManager.selection()
                                if key == "DEL" {
                                    if !pin.isEmpty { pin.removeLast() }
                                    showError = false
                                } else if pin.count < 4 {
                                    pin += key
                                    if pin.count == 4 {
                                        if pin == currentPin {
                                            HapticManager.notification(.success)
                                            onDisable()
                                        } else {
                                            HapticManager.notification(.error)
                                            pin = ""
                                            showError = true
                                        }
                                    }
                                }
                            } label: {
                                Group {
                                    if key == "DEL" {
                                        Text("⌫").font(.system(.title3, design: .rounded, weight: .bold))
                                    } else {
                                        Text(key).font(.system(.title2, design: .rounded, weight: .bold))
                                    }
                                }
                                .foregroundStyle(GeniColor.border)
                                .frame(width: 72, height: 52)
                                .softSurface(GeniColor.card)
                            }
                        }
                    }
                }
            }
        }
    }
}
