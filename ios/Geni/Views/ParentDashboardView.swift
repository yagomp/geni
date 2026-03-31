import SwiftUI

struct ParentDashboardView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pinVerified = false
    @State private var showPinEntry = true
    @State private var pinInput = ""
    @State private var pinError = false
    @State private var showProfileCreation = false
    @State private var editingProfile: ChildProfile? = nil
    @State private var newPin = ""
    @State private var showSetPin = false
    @State private var selectedLanguage: AppLanguage = L.selectedLanguage
    @State private var languageManager = LanguageManager.shared

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
            GeniColor.background.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button {
                        HapticManager.selection()
                        dismiss()
                    } label: {
                        Text("◀️").font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(GeniColor.card)
                            .overlay(
                                Rectangle()
                                    .stroke(GeniColor.border, lineWidth: 3)
                            )
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
                        Rectangle()
                            .fill(i < pinInput.count ? GeniColor.blue : Color.gray.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Rectangle()
                                    .stroke(GeniColor.border, lineWidth: 2)
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
        .navigationBarHidden(true)
    }

    private var settingsContent: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button {
                            HapticManager.selection()
                            dismiss()
                        } label: {
                            Text("◀️").font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(GeniColor.card)
                                .overlay(
                                    Rectangle()
                                        .stroke(GeniColor.border, lineWidth: 3)
                                )
                        }

                        Spacer()

                        Text(L.s(.parentSettings))
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundStyle(GeniColor.border)

                        Spacer()

                        Color.clear.frame(width: 44, height: 44)
                    }

                    profilesSection
                    languageSection
                    progressOverviewSection
                    reminderSection
                    iCloudSyncSection
                    pinSection
                }
                .padding(iPadScale.padding)
                .foregroundStyle(.black)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showProfileCreation) {
            ProfileCreationView(onComplete: { profile in
                viewModel.persistence.saveProfile(profile)
                showProfileCreation = false
            }, onBack: {
                showProfileCreation = false
            })
        }
        .fullScreenCover(item: $editingProfile) { profile in
            ProfileCreationView(onComplete: { updated in
                viewModel.persistence.saveProfile(updated)
                editingProfile = nil
            }, editingProfile: profile, onBack: {
                editingProfile = nil
            })
        }
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
                        viewModel.persistence.saveProfile(profile)
                        ThemeManager.shared.current = theme
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Rectangle()
                                    .fill(themePreviewBg(theme))
                                    .frame(height: 56)
                                    .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 2))

                                HStack(spacing: 6) {
                                    Circle().fill(themePreviewAccent(theme)).frame(width: 14, height: 14)
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(themePreviewCard(theme))
                                        .frame(width: 28, height: 14)
                                        .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
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
                        .brutalistCard(color: isSelected ? themePreviewBg(theme).opacity(0.3) : GeniColor.card, borderWidth: isSelected ? 3 : 2)
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
                    .brutalistCard(color: GeniColor.card, borderWidth: 3)
                }
            }
        }
    }

    private func languageLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return L.s(.languageEnglish)
        case .norwegian: return L.s(.languageNorwegian)
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
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .overlay(
                            Rectangle()
                                .stroke(GeniColor.border, lineWidth: 2)
                        )

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

                    if viewModel.persistence.profiles.count > 1 {
                        Button {
                            HapticManager.selection()
                            viewModel.persistence.deleteProfile(profile.id)
                        } label: {
                            Text("🗑️")
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(12)
                .brutalistCard(color: GeniColor.card, borderWidth: 3)
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
                let totalCorrect = completedChapters.reduce(0) { $0 + $1.correctCount }
                let totalExercises = completedChapters.reduce(0) { $0 + $1.exerciseResults.count }
                let accuracy = totalExercises > 0 ? Int(Double(totalCorrect) / Double(totalExercises) * 100) : 0

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text(avatar.emoji)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(.white)
                            .overlay(
                                Rectangle()
                                    .stroke(GeniColor.border, lineWidth: 2)
                                    .allowsHitTesting(false)
                            )

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
                            .overlay(
                                Rectangle()
                                    .stroke(GeniColor.purple.opacity(0.3), lineWidth: 2)
                                    .allowsHitTesting(false)
                            )
                    }

                    HStack(spacing: 8) {
                        progressStat(emoji: "⭐", value: "\(completedChapters.count)", label: L.s(.chaptersCompleted), color: GeniColor.yellow)
                        progressStat(emoji: "🔥", value: "\(rewards.streakCount)", label: L.s(.streak), color: GeniColor.orange)
                        progressStat(emoji: "🎯", value: "\(accuracy)%", label: L.s(.accuracy), color: GeniColor.green)
                        progressStat(emoji: "⚡", value: "\(rewards.xp)", label: L.s(.totalXP), color: GeniColor.cyan)
                    }

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
                                            .overlay(
                                                Rectangle()
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

                                    Text("\(ch.correctCount)/\(ch.exerciseResults.count)")
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
                .brutalistCard(color: GeniColor.card, borderWidth: 3)
            }
        }
    }

    private func progressStat(emoji: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 14))
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.2), lineWidth: 2)
                .allowsHitTesting(false)
        )
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
            .brutalistCard(color: GeniColor.card, borderWidth: 3)

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
                .brutalistCard(color: GeniColor.card, borderWidth: 3)
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
            .brutalistCard(color: GeniColor.card, borderWidth: 3)
        }
    }

    private var pinSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.pin))
                .font(.system(.headline, design: .rounded, weight: .bold))

            if viewModel.persistence.parentPin != nil {
                Button {
                    HapticManager.selection()
                    showSetPin = true
                } label: {
                    HStack {
                        Text("🔒")
                        Text(L.s(.changePin))
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.blue)
                }
            } else {
                Button {
                    HapticManager.selection()
                    showSetPin = true
                } label: {
                    HStack {
                        Text("🔓")
                        Text(L.s(.setPin))
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(GeniColor.blue)
                }
            }
        }
        .sheet(isPresented: $showSetPin) {
            SetPinView { pin in
                viewModel.persistence.setPin(pin)
                showSetPin = false
            }
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
                                .background(GeniColor.card)
                                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                                .background(
                                    Rectangle()
                                        .fill(GeniColor.border)
                                        .offset(x: 3, y: 3)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SetPinView: View {
    let onSet: (String) -> Void
    @State private var pin = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GeniColor.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(L.s(.setPin))
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(.black)

                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            Rectangle()
                                .fill(i < pin.count ? GeniColor.blue : Color.gray.opacity(0.2))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Rectangle()
                                        .stroke(GeniColor.border, lineWidth: 2)
                                )
                        }
                    }

                    pinPadView
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
                                        HapticManager.notification(.success)
                                        onSet(pin)
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
                                .background(GeniColor.card)
                                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
                                .background(
                                    Rectangle()
                                        .fill(GeniColor.border)
                                        .offset(x: 3, y: 3)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
