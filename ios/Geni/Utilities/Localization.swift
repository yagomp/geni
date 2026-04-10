import Foundation

nonisolated enum LocaleKey: String, Sendable {
    case appName
    case welcome
    case welcomeSubtitle
    case createMyGeni
    case createProfile
    case nickname
    case nicknamePlaceholder
    case age
    case chooseAvatar
    case letsGo
    case cancel
    case next
    case done
    case todaysChapter
    case specialChapter
    case startChapter
    case continueChapter
    case chapterComplete
    case greatJob
    case keepGoing
    case almostThere
    case tryAgain
    case niceJob
    case youGotIt
    case letsKeepGoing
    case correct
    case showAnswer
    case exercise
    case of20
    case stars
    case coins
    case streak
    case day
    case days
    case level
    case xp
    case addition
    case subtraction
    case multiplication
    case division
    case settings
    case parentArea
    case enterPin
    case setPin
    case changePin
    case contactSupport
    case operations
    case profiles
    case addProfile
    case editProfile
    case deleteProfile
    case progressMap
    case rewards
    case badges
    case chapter
    case completed
    case notStarted
    case perfectScore
    case coinsEarned
    case xpEarned
    case starsEarned
    case newBadge
    case chapterOf
    case timeAttack
    case perfectRun
    case bossChapter
    case streakBonus
    case spotlightChapter
    case noChapterToday
    case comeBackTomorrow
    case chaptersCompleted
    case totalCorrect
    case currentStreak
    case bestLevel
    case parentSettings
    case childAge
    case enabledOperations
    case recommended
    case custom
    case pin
    case pinDescription
    case pinRequired
    case wrongPin
    case badgeFirstChapter
    case badgeFirstChapterDesc
    case badgeStreak3
    case badgeStreak3Desc
    case badgeStreak7
    case badgeStreak7Desc
    case badgeChapters10
    case badgeChapters10Desc
    case badgePerfect
    case badgePerfectDesc
    case badgeFastSolver
    case badgeFastSolverDesc
    case badgeMulMaster
    case badgeMulMasterDesc
    case badgeCorrect100
    case badgeCorrect100Desc
    case badgeStreak14
    case badgeStreak14Desc
    case badgeStreak30
    case badgeStreak30Desc
    case total
    case selectProfile
    case dailyChapter
    case specialChallenge
    case clear
    case delete
    case levelUp
    case awesome
    case trueLabel
    case falseLabel
    case whichIsBigger
    case howMany
    case howManyTotal
    case whichHasMore
    case matchConnectInstruction
    case matchThePairs
    case whatComesNext
    case or
    case timeUp
    case reminders
    case dailyReminder
    case reminderTime
    case reminderBody
    case cloudSync
    case syncCode
    case syncCodeDesc
    case syncNow
    case restore
    case lastSync
    case enterSyncCode
    case enterSyncCodeDesc
    case adaptiveDifficulty
    case adaptiveDifficultyDesc
    case premium
    case progress
    case accuracy
    case totalXP
    case recentChapters
    case noChaptersYet
    case today
    case yesterday
    case back
    case readingTime
    case readingComplete
    case readByMyself
    case readToMe
    case listenToMeRead
    case readBySelfDesc
    case readToMeDesc
    case listenToMeDesc
    case minutes
    case pause
    case play
    case micPermissionNeeded
    case amazingReading
    case dailyBonusTitle
    case dailyBonusDesc
    case mathComplete
    case readingSection
    case startReading
    case readingDone
    case mathAndReading
    case mathOnly
    case optionalLabel
    case theme
    case themeStandard
    case themeOcean
    case themeBlossom
    case badgeFirstReading
    case badgeFirstReadingDesc
    case badgeReading5
    case badgeReading5Desc
    case badgeReadingMaster
    case badgeReadingMasterDesc
    case badgeFullChapter
    case badgeFullChapterDesc
    case todaysMission
    case missionComplete
    case mathProgress
    case readingProgress
    case start
    case greatJobMath
    case nowLetsRead
    case continueToReading
    case missionBonusTitle
    case missionBonusDesc
    case yourName
    case whosPlaying
    case iAm
    case extraModes
    case fullMissionComplete
    case mathDone
    case readingDone2
    case bonusEarned
    case missionStreak
    case finishMissionToUnlockChallenges
    case finishMathToUnlockChallenges
    case language
    case languageSystem
    case languageEnglish
    case languageNorwegian
    case languageSpanish
    case languagePortuguese
    case mathPractice
    case recommendedForAge
    case iCloudSync
    case iCloudSyncDesc
    case iCloudNotAvailable
    case synced
    case challengeTimeLeft
    case challengesClosed
    case seeYouTomorrow
    case changeProfile
    case add
    case evenNumber
    case oddNumber
    case topicNumbers
    case topicAddSubBasic
    case topicStrategies
    case topicTensCrossing
    case topicTimeAndCalendar
    case topicLargerNumbers
    case topicAddSubAdvanced
    case topicProblemSolving
    case topicMeasurement
    case topicLogicPatterns
    case topicProgress
    case topicLocked
    case topicCurrent
    case speechRecognitionUnavailable
    case audioSessionError
    case audioEngineStartError
}

nonisolated enum AppLanguage: String, Sendable, CaseIterable {
    case english
    case norwegian
    case spanish
    case portuguese

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .norwegian: return "🇳🇴"
        case .spanish: return "🇪🇸"
        case .portuguese: return "🇵🇹"
        }
    }
}

@Observable
class LanguageManager {
    static let shared = LanguageManager()
    private let languageKey = "geni_app_language"

    var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: languageKey)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "geni_app_language"),
           let lang = AppLanguage(rawValue: raw) {
            self.current = lang
        } else {
            self.current = Self.language(for: Locale.preferredLanguages.first ?? "en")
        }
    }

    static func language(for preferred: String) -> AppLanguage {
        if preferred.hasPrefix("nb") || preferred.hasPrefix("nn") || preferred.hasPrefix("no") {
            return .norwegian
        }
        if preferred.hasPrefix("es") {
            return .spanish
        }
        if preferred.hasPrefix("pt") {
            return .portuguese
        }
        return .english
    }
}

nonisolated enum L {
    private static let languageKey = "geni_app_language"

    static var selectedLanguage: AppLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: languageKey),
               let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            return systemLanguage
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
        }
    }

    private static var systemLanguage: AppLanguage {
        LanguageManager.language(for: Locale.preferredLanguages.first ?? "en")
    }

    static var isNorwegian: Bool {
        selectedLanguage == .norwegian
    }

    static var speechLocaleIdentifier: String {
        switch selectedLanguage {
        case .english: return "en-US"
        case .norwegian: return "nb-NO"
        case .spanish: return "es-ES"
        case .portuguese: return "pt-PT"
        }
    }

    static func s(_ key: LocaleKey) -> String {
        s(key, lang: selectedLanguage)
    }

    static func s(_ key: LocaleKey, lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return english(key)
        case .norwegian:
            return norwegian(key)
        case .spanish:
            return spanish(key)
        case .portuguese:
            return portuguese(key)
        }
    }

    private static func english(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "Welcome to Geni!"
        case .welcomeSubtitle: return "Learning is an adventure"
        case .createMyGeni: return "Create my own Geni"
        case .createProfile: return "Create Profile"
        case .nickname: return "Nickname"
        case .nicknamePlaceholder: return "Your name"
        case .age: return "Age"
        case .chooseAvatar: return "Choose Avatar"
        case .letsGo: return "Let\u{2019}s go!"
        case .cancel: return "Cancel"
        case .next: return "Next"
        case .done: return "Done"
        case .todaysChapter: return "Today\u{2019}s Chapter"
        case .specialChapter: return "Special Challenge"
        case .startChapter: return "Start"
        case .continueChapter: return "Continue"
        case .chapterComplete: return "Chapter Complete!"
        case .greatJob: return "Great job!"
        case .keepGoing: return "Keep going!"
        case .almostThere: return "Almost!"
        case .tryAgain: return "Try again!"
        case .niceJob: return "Nice job!"
        case .youGotIt: return "You got it!"
        case .letsKeepGoing: return "Let\u{2019}s keep going!"
        case .correct: return "Correct!"
        case .showAnswer: return "Show Answer"
        case .exercise: return "Exercise"
        case .of20: return "of 20"
        case .stars: return "Stars"
        case .coins: return "Coins"
        case .streak: return "Streak"
        case .day: return "day"
        case .days: return "days"
        case .level: return "Level"
        case .xp: return "XP"
        case .addition: return "Addition"
        case .subtraction: return "Subtraction"
        case .multiplication: return "Multiplication"
        case .division: return "Division"
        case .settings: return "Settings"
        case .parentArea: return "Parent Area"
        case .enterPin: return "Enter PIN"
        case .setPin: return "Set PIN"
        case .changePin: return "Change PIN"
        case .contactSupport: return "Contact Us"
        case .operations: return "Operations"
        case .profiles: return "Profiles"
        case .addProfile: return "Add Profile"
        case .editProfile: return "Edit Profile"
        case .deleteProfile: return "Delete Profile"
        case .progressMap: return "Progress"
        case .rewards: return "Rewards"
        case .badges: return "Badges"
        case .chapter: return "Chapter"
        case .completed: return "Completed"
        case .notStarted: return "Not started"
        case .perfectScore: return "Perfect!"
        case .coinsEarned: return "Coins earned"
        case .xpEarned: return "XP earned"
        case .starsEarned: return "Stars earned"
        case .newBadge: return "New badge!"
        case .chapterOf: return "Chapter"
        case .timeAttack: return "Time Attack"
        case .perfectRun: return "Perfect Run"
        case .bossChapter: return "Boss Chapter"
        case .streakBonus: return "Streak Bonus"
        case .spotlightChapter: return "Spotlight"
        case .noChapterToday: return "All done for today!"
        case .comeBackTomorrow: return "Come back tomorrow"
        case .chaptersCompleted: return "Chapters"
        case .totalCorrect: return "Correct"
        case .currentStreak: return "Current Streak"
        case .bestLevel: return "Level"
        case .parentSettings: return "Parent Settings"
        case .childAge: return "Child\u{2019}s Age"
        case .enabledOperations: return "Enabled Operations"
        case .recommended: return "Recommended"
        case .custom: return "Custom"
        case .pin: return "PIN"
        case .pinDescription: return "Prevents kids from accessing parent settings"
        case .pinRequired: return "Enter your 4-digit PIN"
        case .wrongPin: return "Wrong PIN"
        case .badgeFirstChapter: return "First Steps"
        case .badgeFirstChapterDesc: return "Complete your first chapter"
        case .badgeStreak3: return "On Fire"
        case .badgeStreak3Desc: return "3-day streak"
        case .badgeStreak7: return "Week Warrior"
        case .badgeStreak7Desc: return "7-day streak"
        case .badgeChapters10: return "Bookworm"
        case .badgeChapters10Desc: return "Complete 10 chapters"
        case .badgePerfect: return "Perfect"
        case .badgePerfectDesc: return "Get 3 stars in a chapter"
        case .badgeFastSolver: return "Fast Solver"
        case .badgeFastSolverDesc: return "15+ first-try answers"
        case .badgeMulMaster: return "Multiply Master"
        case .badgeMulMasterDesc: return "Use multiplication"
        case .badgeCorrect100: return "Century"
        case .badgeCorrect100Desc: return "100 correct answers"
        case .badgeStreak14: return "Dedicated"
        case .badgeStreak14Desc: return "14-day streak"
        case .badgeStreak30: return "Champion"
        case .badgeStreak30Desc: return "30-day streak"
        case .total: return "Total"
        case .selectProfile: return "Who\u{2019}s playing?"
        case .dailyChapter: return "Daily Chapter"
        case .specialChallenge: return "Special Challenge"
        case .clear: return "Clear"
        case .delete: return "Delete"
        case .levelUp: return "Level Up!"
        case .awesome: return "Awesome!"
        case .trueLabel: return "True"
        case .falseLabel: return "False"
        case .whichIsBigger: return "Which is bigger?"
        case .howMany: return "How many?"
        case .howManyTotal: return "How many in total?"
        case .whichHasMore: return "Which has more?"
        case .matchConnectInstruction: return "Draw lines to match the boxes."
        case .matchThePairs: return "Match the pairs"
        case .whatComesNext: return "What comes next?"
        case .or: return "or"
        case .timeUp: return "Time\u{2019}s up!"
        case .reminders: return "Reminders"
        case .dailyReminder: return "Daily Reminder"
        case .reminderTime: return "Reminder Time"
        case .reminderBody: return "Time for today\u{2019}s math chapter!"
        case .cloudSync: return "Cloud Sync"
        case .syncCode: return "Sync Code"
        case .syncCodeDesc: return "Use this code to restore on another device"
        case .syncNow: return "Sync Now"
        case .restore: return "Restore"
        case .lastSync: return "Last sync"
        case .enterSyncCode: return "Enter sync code"
        case .enterSyncCodeDesc: return "Enter the 6-character code from your other device"
        case .adaptiveDifficulty: return "Adaptive Difficulty"
        case .adaptiveDifficultyDesc: return "Adjusts difficulty based on performance"
        case .premium: return "Premium"
        case .progress: return "Progress"
        case .accuracy: return "Accuracy"
        case .totalXP: return "Total XP"
        case .recentChapters: return "Recent Chapters"
        case .noChaptersYet: return "No chapters yet"
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .back: return "Back"
        case .readingTime: return "Reading Time"
        case .readingComplete: return "Reading Complete!"
        case .readByMyself: return "Read by myself"
        case .readToMe: return "Read to me"
        case .listenToMeRead: return "Listen to me read"
        case .readBySelfDesc: return "Follow the highlighted words"
        case .readToMeDesc: return "The app reads aloud for you"
        case .listenToMeDesc: return "Read aloud and get feedback"
        case .minutes: return "min"
        case .pause: return "Pause"
        case .play: return "Play"
        case .micPermissionNeeded: return "Microphone access needed"
        case .amazingReading: return "Amazing reading!"
        case .dailyBonusTitle: return "Daily Full Chapter Bonus!"
        case .dailyBonusDesc: return "Math + Reading complete today"
        case .mathComplete: return "Math"
        case .readingSection: return "Reading"
        case .startReading: return "Start Reading"
        case .readingDone: return "Reading done!"
        case .mathAndReading: return "Math & Reading"
        case .mathOnly: return "Math"
        case .optionalLabel: return "(optional)"
        case .theme: return "Theme"
        case .themeStandard: return "Standard"
        case .themeOcean: return "Ocean"
        case .themeBlossom: return "Blossom"
        case .badgeFirstReading: return "First Read"
        case .badgeFirstReadingDesc: return "Complete your first reading"
        case .badgeReading5: return "Story Lover"
        case .badgeReading5Desc: return "Complete 5 readings"
        case .badgeReadingMaster: return "Reading Master"
        case .badgeReadingMasterDesc: return "30 minutes of reading"
        case .badgeFullChapter: return "Full Day"
        case .badgeFullChapterDesc: return "Complete math + reading in one day"
        case .todaysMission: return "Today\u{2019}s Mission"
        case .missionComplete: return "Mission Complete!"
        case .mathProgress: return "Math"
        case .readingProgress: return "Reading"
        case .start: return "START"
        case .greatJobMath: return "Great job!"
        case .nowLetsRead: return "Now let\u{2019}s read"
        case .continueToReading: return "Continue"
        case .missionBonusTitle: return "Mission Bonus!"
        case .missionBonusDesc: return "You completed math + reading today"
        case .yourName: return "Your name"
        case .whosPlaying: return "Who\u{2019}s playing?"
        case .iAm: return "I am"
        case .extraModes: return "Extra Challenges"
        case .fullMissionComplete: return "Full Mission Complete!"
        case .mathDone: return "Math done"
        case .readingDone2: return "Reading done"
        case .bonusEarned: return "Bonus earned"
        case .missionStreak: return "Mission Streak"
        case .finishMissionToUnlockChallenges: return "Finish today's mission to unlock challenges"
        case .finishMathToUnlockChallenges: return "Finish today's math to unlock challenges"
        case .language: return "Language"
        case .languageSystem: return "System Default"
        case .languageEnglish: return "English"
        case .languageNorwegian: return "Norwegian"
        case .languageSpanish: return "Spanish"
        case .languagePortuguese: return "Portuguese"
        case .mathPractice: return "What to practice"
        case .recommendedForAge: return "Recommended for your age!"
        case .iCloudSync: return "iCloud Sync"
        case .iCloudSyncDesc: return "Sync across your devices"
        case .iCloudNotAvailable: return "Sign in to iCloud in Settings"
        case .synced: return "Synced"
        case .challengeTimeLeft: return "Time left to play"
        case .challengesClosed: return "Challenges closed!"
        case .seeYouTomorrow: return "See you tomorrow"
        case .changeProfile: return "Change"
        case .add: return "Add"
        case .evenNumber: return "Even"
        case .oddNumber: return "Odd"
        case .topicNumbers: return "Numbers"
        case .topicAddSubBasic: return "Add & Subtract"
        case .topicStrategies: return "Strategies"
        case .topicTensCrossing: return "Tens Crossing"
        case .topicTimeAndCalendar: return "Time & Calendar"
        case .topicLargerNumbers: return "Larger Numbers"
        case .topicAddSubAdvanced: return "Advanced Math"
        case .topicProblemSolving: return "Problem Solving"
        case .topicMeasurement: return "Measurement"
        case .topicLogicPatterns: return "Logic & Patterns"
        case .topicProgress: return "Topic Progress"
        case .topicLocked: return "Locked"
        case .topicCurrent: return "Current"
        case .speechRecognitionUnavailable: return "Speech recognition not available"
        case .audioSessionError: return "Audio session error"
        case .audioEngineStartError: return "Could not start audio engine"
        }
    }

    private static func norwegian(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "Velkommen til Geni!"
        case .welcomeSubtitle: return "L\u{00E6}ring er et eventyr"
        case .createMyGeni: return "Lag min egen Geni"
        case .createProfile: return "Lag profil"
        case .nickname: return "Kallenavn"
        case .nicknamePlaceholder: return "Ditt navn"
        case .age: return "Alder"
        case .chooseAvatar: return "Velg avatar"
        case .letsGo: return "Kj\u{00F8}r!"
        case .cancel: return "Avbryt"
        case .next: return "Neste"
        case .done: return "Ferdig"
        case .todaysChapter: return "Dagens kapittel"
        case .specialChapter: return "Spesialutfordring"
        case .startChapter: return "Start"
        case .continueChapter: return "Fortsett"
        case .chapterComplete: return "Kapittel fullf\u{00F8}rt!"
        case .greatJob: return "Kjempebra!"
        case .keepGoing: return "Fortsett!"
        case .almostThere: return "Nesten!"
        case .tryAgain: return "Pr\u{00F8}v igjen!"
        case .niceJob: return "Bra jobba!"
        case .youGotIt: return "Riktig!"
        case .letsKeepGoing: return "Vi fortsetter!"
        case .correct: return "Riktig!"
        case .showAnswer: return "Vis svaret"
        case .exercise: return "Oppgave"
        case .of20: return "av 20"
        case .stars: return "Stjerner"
        case .coins: return "Mynter"
        case .streak: return "Rekke"
        case .day: return "dag"
        case .days: return "dager"
        case .level: return "Niv\u{00E5}"
        case .xp: return "XP"
        case .addition: return "Addisjon"
        case .subtraction: return "Subtraksjon"
        case .multiplication: return "Multiplikasjon"
        case .division: return "Divisjon"
        case .settings: return "Innstillinger"
        case .parentArea: return "Foreldreomr\u{00E5}de"
        case .enterPin: return "Skriv inn PIN"
        case .setPin: return "Sett PIN"
        case .changePin: return "Endre PIN"
        case .contactSupport: return "Kontakt oss"
        case .operations: return "Regnearter"
        case .profiles: return "Profiler"
        case .addProfile: return "Legg til profil"
        case .editProfile: return "Rediger profil"
        case .deleteProfile: return "Slett profil"
        case .progressMap: return "Fremgang"
        case .rewards: return "Bel\u{00F8}nninger"
        case .badges: return "Merker"
        case .chapter: return "Kapittel"
        case .completed: return "Fullf\u{00F8}rt"
        case .notStarted: return "Ikke startet"
        case .perfectScore: return "Perfekt!"
        case .coinsEarned: return "Mynter tjent"
        case .xpEarned: return "XP tjent"
        case .starsEarned: return "Stjerner tjent"
        case .newBadge: return "Nytt merke!"
        case .chapterOf: return "Kapittel"
        case .timeAttack: return "Tidsangrep"
        case .perfectRun: return "Perfekt runde"
        case .bossChapter: return "Bosskapittel"
        case .streakBonus: return "Rekkebonus"
        case .spotlightChapter: return "Fokus"
        case .noChapterToday: return "Ferdig for i dag!"
        case .comeBackTomorrow: return "Kom tilbake i morgen"
        case .chaptersCompleted: return "Kapitler"
        case .totalCorrect: return "Riktige"
        case .currentStreak: return "N\u{00E5}v\u{00E6}rende rekke"
        case .bestLevel: return "Niv\u{00E5}"
        case .parentSettings: return "Foreldreinnstillinger"
        case .childAge: return "Barnets alder"
        case .enabledOperations: return "Aktiverte regnearter"
        case .recommended: return "Anbefalt"
        case .custom: return "Tilpasset"
        case .pin: return "PIN"
        case .pinDescription: return "Hindrer barn fra å åpne foreldreinnstillinger"
        case .pinRequired: return "Skriv inn din 4-sifrede PIN"
        case .wrongPin: return "Feil PIN"
        case .badgeFirstChapter: return "F\u{00F8}rste steg"
        case .badgeFirstChapterDesc: return "Fullf\u{00F8}r ditt f\u{00F8}rste kapittel"
        case .badgeStreak3: return "I fyr og flamme"
        case .badgeStreak3Desc: return "3 dager p\u{00E5} rad"
        case .badgeStreak7: return "Ukekriger"
        case .badgeStreak7Desc: return "7 dager p\u{00E5} rad"
        case .badgeChapters10: return "Bokorm"
        case .badgeChapters10Desc: return "Fullf\u{00F8}r 10 kapitler"
        case .badgePerfect: return "Perfekt"
        case .badgePerfectDesc: return "F\u{00E5} 3 stjerner i et kapittel"
        case .badgeFastSolver: return "Rask l\u{00F8}ser"
        case .badgeFastSolverDesc: return "15+ riktige p\u{00E5} f\u{00F8}rste fors\u{00F8}k"
        case .badgeMulMaster: return "Gangemester"
        case .badgeMulMasterDesc: return "Bruk multiplikasjon"
        case .badgeCorrect100: return "Hundre"
        case .badgeCorrect100Desc: return "100 riktige svar"
        case .badgeStreak14: return "Dedikert"
        case .badgeStreak14Desc: return "14 dager p\u{00E5} rad"
        case .badgeStreak30: return "Mester"
        case .badgeStreak30Desc: return "30 dager p\u{00E5} rad"
        case .total: return "Totalt"
        case .selectProfile: return "Hvem spiller?"
        case .dailyChapter: return "Dagens kapittel"
        case .specialChallenge: return "Spesialutfordring"
        case .clear: return "Slett"
        case .delete: return "Slett"
        case .levelUp: return "Niv\u{00E5} opp!"
        case .awesome: return "Fantastisk!"
        case .trueLabel: return "Riktig"
        case .falseLabel: return "Feil"
        case .whichIsBigger: return "Hvilken er st\u{00F8}rst?"
        case .howMany: return "Hvor mange?"
        case .howManyTotal: return "Hvor mange til sammen?"
        case .whichHasMore: return "Hvilken har flest?"
        case .matchConnectInstruction: return "Tegn linjer for \u{00E5} matche boksene."
        case .matchThePairs: return "Koble sammen parene"
        case .whatComesNext: return "Hva kommer neste?"
        case .or: return "eller"
        case .timeUp: return "Tiden er ute!"
        case .reminders: return "P\u{00E5}minnelser"
        case .dailyReminder: return "Daglig p\u{00E5}minnelse"
        case .reminderTime: return "P\u{00E5}minnelsestid"
        case .reminderBody: return "Tid for dagens mattekapittel!"
        case .cloudSync: return "Skysynkronisering"
        case .syncCode: return "Synkroniseringskode"
        case .syncCodeDesc: return "Bruk denne koden for \u{00E5} gjenopprette p\u{00E5} en annen enhet"
        case .syncNow: return "Synk n\u{00E5}"
        case .restore: return "Gjenopprett"
        case .lastSync: return "Siste synk"
        case .enterSyncCode: return "Skriv inn synkroniseringskode"
        case .enterSyncCodeDesc: return "Skriv inn 6-tegns koden fra din andre enhet"
        case .adaptiveDifficulty: return "Adaptiv vanskelighetsgrad"
        case .adaptiveDifficultyDesc: return "Justerer vanskelighetsgrad basert p\u{00E5} prestasjoner"
        case .premium: return "Premium"
        case .progress: return "Fremgang"
        case .accuracy: return "N\u{00F8}yaktighet"
        case .totalXP: return "Total XP"
        case .recentChapters: return "Siste kapitler"
        case .noChaptersYet: return "Ingen kapitler enn\u{00E5}"
        case .today: return "I dag"
        case .yesterday: return "I g\u{00E5}r"
        case .back: return "Tilbake"
        case .readingTime: return "Lesetid"
        case .readingComplete: return "Lesing fullf\u{00F8}rt!"
        case .readByMyself: return "Les selv"
        case .readToMe: return "Les for meg"
        case .listenToMeRead: return "H\u{00F8}r meg lese"
        case .readBySelfDesc: return "F\u{00F8}lg de markerte ordene"
        case .readToMeDesc: return "Appen leser h\u{00F8}yt for deg"
        case .listenToMeDesc: return "Les h\u{00F8}yt og f\u{00E5} tilbakemelding"
        case .minutes: return "min"
        case .pause: return "Pause"
        case .play: return "Spill"
        case .micPermissionNeeded: return "Mikrofontilgang trengs"
        case .amazingReading: return "Fantastisk lesing!"
        case .dailyBonusTitle: return "Daglig fullkapittelbonus!"
        case .dailyBonusDesc: return "Matte + Lesing fullf\u{00F8}rt i dag"
        case .mathComplete: return "Matte"
        case .readingSection: return "Lesing"
        case .startReading: return "Start lesing"
        case .readingDone: return "Lesing ferdig!"
        case .mathAndReading: return "Matte og lesing"
        case .mathOnly: return "Matte"
        case .optionalLabel: return "(valgfritt)"
        case .theme: return "Tema"
        case .themeStandard: return "Standard"
        case .themeOcean: return "Hav"
        case .themeBlossom: return "Blomst"
        case .badgeFirstReading: return "F\u{00F8}rste lesing"
        case .badgeFirstReadingDesc: return "Fullf\u{00F8}r din f\u{00F8}rste lesing"
        case .badgeReading5: return "Historieelsker"
        case .badgeReading5Desc: return "Fullf\u{00F8}r 5 lesinger"
        case .badgeReadingMaster: return "Lesemester"
        case .badgeReadingMasterDesc: return "30 minutter med lesing"
        case .badgeFullChapter: return "Full dag"
        case .badgeFullChapterDesc: return "Fullf\u{00F8}r matte + lesing p\u{00E5} en dag"
        case .todaysMission: return "Dagens oppdrag"
        case .missionComplete: return "Oppdrag fullf\u{00F8}rt!"
        case .mathProgress: return "Matte"
        case .readingProgress: return "Lesing"
        case .start: return "START"
        case .greatJobMath: return "Kjempebra!"
        case .nowLetsRead: return "N\u{00E5} skal vi lese"
        case .continueToReading: return "Fortsett"
        case .missionBonusTitle: return "Oppdragsbonus!"
        case .missionBonusDesc: return "Du fullf\u{00F8}rte matte + lesing i dag"
        case .yourName: return "Ditt navn"
        case .whosPlaying: return "Hvem spiller?"
        case .iAm: return "Jeg er"
        case .extraModes: return "Ekstra utfordringer"
        case .fullMissionComplete: return "Fullt oppdrag fullf\u{00F8}rt!"
        case .mathDone: return "Matte ferdig"
        case .readingDone2: return "Lesing ferdig"
        case .bonusEarned: return "Bonus opptjent"
        case .missionStreak: return "Oppdragsrekke"
        case .finishMissionToUnlockChallenges: return "Fullfor dagens oppdrag for a lase opp utfordringer"
        case .finishMathToUnlockChallenges: return "Fullfor dagens matte for a lase opp utfordringer"
        case .language: return "Spr\u{00E5}k"
        case .languageSystem: return "Systemstandard"
        case .languageEnglish: return "Engelsk"
        case .languageNorwegian: return "Norsk"
        case .languageSpanish: return "Spansk"
        case .languagePortuguese: return "Portugisisk"
        case .mathPractice: return "Hva skal vi \u{00F8}ve p\u{00E5}"
        case .recommendedForAge: return "Anbefalt for din alder!"
        case .iCloudSync: return "iCloud-synk"
        case .iCloudSyncDesc: return "Synk mellom enhetene dine"
        case .iCloudNotAvailable: return "Logg inn p\u{00E5} iCloud i Innstillinger"
        case .synced: return "Synkronisert"
        case .challengeTimeLeft: return "Tid igjen \u{00E5} spille"
        case .challengesClosed: return "Utfordringer stengt!"
        case .seeYouTomorrow: return "Vi ses i morgen"
        case .changeProfile: return "Bytt"
        case .add: return "Legg til"
        case .evenNumber: return "Partall"
        case .oddNumber: return "Oddetall"
        case .topicNumbers: return "Tall"
        case .topicAddSubBasic: return "Addisjon og subtraksjon"
        case .topicStrategies: return "Regnestrategier"
        case .topicTensCrossing: return "Tierovergang"
        case .topicTimeAndCalendar: return "Tid og kalender"
        case .topicLargerNumbers: return "St\u{00F8}rre tall"
        case .topicAddSubAdvanced: return "Avansert regning"
        case .topicProblemSolving: return "Probleml\u{00F8}sing"
        case .topicMeasurement: return "Lengde og areal"
        case .topicLogicPatterns: return "Logikk og m\u{00F8}nstre"
        case .topicProgress: return "Temafremgang"
        case .topicLocked: return "L\u{00E5}st"
        case .topicCurrent: return "N\u{00E5}v\u{00E6}rende"
        case .speechRecognitionUnavailable: return "Talegjenkjenning er ikke tilgjengelig"
        case .audioSessionError: return "Feil i lydsesjonen"
        case .audioEngineStartError: return "Kunne ikke starte lydmotoren"
        }
    }

    private static func spanish(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "\u{00A1}Bienvenido a Geni!"
        case .welcomeSubtitle: return "Aprender es una aventura"
        case .createMyGeni: return "Crear mi propio Geni"
        case .createProfile: return "Crear perfil"
        case .nickname: return "Apodo"
        case .nicknamePlaceholder: return "Tu nombre"
        case .age: return "Edad"
        case .chooseAvatar: return "Elegir avatar"
        case .letsGo: return "\u{00A1}Vamos!"
        case .cancel: return "Cancelar"
        case .next: return "Siguiente"
        case .done: return "Listo"
        case .todaysChapter: return "Cap\u{00ED}tulo de hoy"
        case .specialChapter: return "Desaf\u{00ED}o especial"
        case .startChapter: return "Empezar"
        case .continueChapter: return "Continuar"
        case .chapterComplete: return "\u{00A1}Cap\u{00ED}tulo completado!"
        case .greatJob: return "\u{00A1}Muy bien!"
        case .keepGoing: return "\u{00A1}Sigue as\u{00ED}!"
        case .almostThere: return "\u{00A1}Casi!"
        case .tryAgain: return "\u{00A1}Int\u{00E9}ntalo de nuevo!"
        case .niceJob: return "\u{00A1}Buen trabajo!"
        case .youGotIt: return "\u{00A1}Lo lograste!"
        case .letsKeepGoing: return "\u{00A1}Sigamos!"
        case .correct: return "\u{00A1}Correcto!"
        case .showAnswer: return "Mostrar respuesta"
        case .exercise: return "Ejercicio"
        case .of20: return "de 20"
        case .stars: return "Estrellas"
        case .coins: return "Monedas"
        case .streak: return "Racha"
        case .day: return "d\u{00ED}a"
        case .days: return "d\u{00ED}as"
        case .level: return "Nivel"
        case .xp: return "XP"
        case .addition: return "Suma"
        case .subtraction: return "Resta"
        case .multiplication: return "Multiplicaci\u{00F3}n"
        case .division: return "Divisi\u{00F3}n"
        case .settings: return "Configuraci\u{00F3}n"
        case .parentArea: return "\u{00C1}rea para padres"
        case .enterPin: return "Introducir PIN"
        case .setPin: return "Crear PIN"
        case .changePin: return "Cambiar PIN"
        case .contactSupport: return "Cont\u{00E1}ctanos"
        case .operations: return "Operaciones"
        case .profiles: return "Perfiles"
        case .addProfile: return "Agregar perfil"
        case .editProfile: return "Editar perfil"
        case .deleteProfile: return "Eliminar perfil"
        case .progressMap: return "Progreso"
        case .rewards: return "Recompensas"
        case .badges: return "Insignias"
        case .chapter: return "Cap\u{00ED}tulo"
        case .completed: return "Completado"
        case .notStarted: return "Sin empezar"
        case .perfectScore: return "\u{00A1}Perfecto!"
        case .coinsEarned: return "Monedas ganadas"
        case .xpEarned: return "XP ganada"
        case .starsEarned: return "Estrellas ganadas"
        case .newBadge: return "\u{00A1}Nueva insignia!"
        case .chapterOf: return "Cap\u{00ED}tulo"
        case .timeAttack: return "Contrarreloj"
        case .perfectRun: return "Ronda perfecta"
        case .bossChapter: return "Cap\u{00ED}tulo jefe"
        case .streakBonus: return "Bono de racha"
        case .spotlightChapter: return "Destacado"
        case .noChapterToday: return "\u{00A1}Todo listo por hoy!"
        case .comeBackTomorrow: return "Vuelve ma\u{00F1}ana"
        case .chaptersCompleted: return "Cap\u{00ED}tulos"
        case .totalCorrect: return "Aciertos"
        case .currentStreak: return "Racha actual"
        case .bestLevel: return "Nivel"
        case .parentSettings: return "Configuraci\u{00F3}n para padres"
        case .childAge: return "Edad del ni\u{00F1}o"
        case .enabledOperations: return "Operaciones activadas"
        case .recommended: return "Recomendado"
        case .custom: return "Personalizado"
        case .pin: return "PIN"
        case .pinDescription: return "Impide que los ni\u{00F1}os accedan a los ajustes de padres"
        case .pinRequired: return "Introduce tu PIN de 4 d\u{00ED}gitos"
        case .wrongPin: return "PIN incorrecto"
        case .badgeFirstChapter: return "Primeros pasos"
        case .badgeFirstChapterDesc: return "Completa tu primer cap\u{00ED}tulo"
        case .badgeStreak3: return "En racha"
        case .badgeStreak3Desc: return "Racha de 3 d\u{00ED}as"
        case .badgeStreak7: return "H\u{00E9}roe semanal"
        case .badgeStreak7Desc: return "Racha de 7 d\u{00ED}as"
        case .badgeChapters10: return "Rat\u{00F3}n de biblioteca"
        case .badgeChapters10Desc: return "Completa 10 cap\u{00ED}tulos"
        case .badgePerfect: return "Perfecto"
        case .badgePerfectDesc: return "Consigue 3 estrellas en un cap\u{00ED}tulo"
        case .badgeFastSolver: return "R\u{00E1}pido para resolver"
        case .badgeFastSolverDesc: return "15+ respuestas correctas al primer intento"
        case .badgeMulMaster: return "Maestro de la multiplicaci\u{00F3}n"
        case .badgeMulMasterDesc: return "Usa la multiplicaci\u{00F3}n"
        case .badgeCorrect100: return "Centenar"
        case .badgeCorrect100Desc: return "100 respuestas correctas"
        case .badgeStreak14: return "Constante"
        case .badgeStreak14Desc: return "Racha de 14 d\u{00ED}as"
        case .badgeStreak30: return "Campe\u{00F3}n"
        case .badgeStreak30Desc: return "Racha de 30 d\u{00ED}as"
        case .total: return "Total"
        case .selectProfile: return "\u{00BF}Qui\u{00E9}n va a jugar?"
        case .dailyChapter: return "Cap\u{00ED}tulo diario"
        case .specialChallenge: return "Desaf\u{00ED}o especial"
        case .clear: return "Borrar"
        case .delete: return "Eliminar"
        case .levelUp: return "\u{00A1}Subiste de nivel!"
        case .awesome: return "\u{00A1}Incre\u{00ED}ble!"
        case .trueLabel: return "Verdadero"
        case .falseLabel: return "Falso"
        case .whichIsBigger: return "¿Cuál es mayor?"
        case .howMany: return "¿Cuántos hay?"
        case .howManyTotal: return "¿Cuántos hay en total?"
        case .whichHasMore: return "¿Cuál tiene más?"
        case .matchConnectInstruction: return "Dibuja líneas para unir las cajas."
        case .matchThePairs: return "Une las parejas"
        case .whatComesNext: return "\u{00BF}Qu\u{00E9} viene despu\u{00E9}s?"
        case .or: return "o"
        case .timeUp: return "\u{00A1}Se acab\u{00F3} el tiempo!"
        case .reminders: return "Recordatorios"
        case .dailyReminder: return "Recordatorio diario"
        case .reminderTime: return "Hora del recordatorio"
        case .reminderBody: return "\u{00A1}Es hora del cap\u{00ED}tulo de mates de hoy!"
        case .cloudSync: return "Sincronizaci\u{00F3}n en la nube"
        case .syncCode: return "C\u{00F3}digo de sincronizaci\u{00F3}n"
        case .syncCodeDesc: return "Usa este c\u{00F3}digo para restaurar en otro dispositivo"
        case .syncNow: return "Sincronizar ahora"
        case .restore: return "Restaurar"
        case .lastSync: return "\u{00DA}ltima sincronizaci\u{00F3}n"
        case .enterSyncCode: return "Introduce el c\u{00F3}digo de sincronizaci\u{00F3}n"
        case .enterSyncCodeDesc: return "Introduce el c\u{00F3}digo de 6 caracteres de tu otro dispositivo"
        case .adaptiveDifficulty: return "Dificultad adaptativa"
        case .adaptiveDifficultyDesc: return "Ajusta la dificultad seg\u{00FA}n el rendimiento"
        case .premium: return "Premium"
        case .progress: return "Progreso"
        case .accuracy: return "Precisi\u{00F3}n"
        case .totalXP: return "XP total"
        case .recentChapters: return "Cap\u{00ED}tulos recientes"
        case .noChaptersYet: return "Todav\u{00ED}a no hay cap\u{00ED}tulos"
        case .today: return "Hoy"
        case .yesterday: return "Ayer"
        case .back: return "Atr\u{00E1}s"
        case .readingTime: return "Tiempo de lectura"
        case .readingComplete: return "\u{00A1}Lectura completada!"
        case .readByMyself: return "Leer por mi cuenta"
        case .readToMe: return "L\u{00E9}emelo"
        case .listenToMeRead: return "Esc\u{00FA}chame leer"
        case .readBySelfDesc: return "Sigue las palabras resaltadas"
        case .readToMeDesc: return "La app te lee en voz alta"
        case .listenToMeDesc: return "Lee en voz alta y recibe comentarios"
        case .minutes: return "min"
        case .pause: return "Pausa"
        case .play: return "Reproducir"
        case .micPermissionNeeded: return "Se necesita acceso al micr\u{00F3}fono"
        case .amazingReading: return "\u{00A1}Lectura incre\u{00ED}ble!"
        case .dailyBonusTitle: return "\u{00A1}Bono diario por completar todo el cap\u{00ED}tulo!"
        case .dailyBonusDesc: return "Mates + lectura completadas hoy"
        case .mathComplete: return "Mates"
        case .readingSection: return "Lectura"
        case .startReading: return "Empezar a leer"
        case .readingDone: return "\u{00A1}Lectura terminada!"
        case .mathAndReading: return "Mates y lectura"
        case .mathOnly: return "Mates"
        case .optionalLabel: return "(opcional)"
        case .theme: return "Tema"
        case .themeStandard: return "Est\u{00E1}ndar"
        case .themeOcean: return "Oc\u{00E9}ano"
        case .themeBlossom: return "Floraci\u{00F3}n"
        case .badgeFirstReading: return "Primera lectura"
        case .badgeFirstReadingDesc: return "Completa tu primera lectura"
        case .badgeReading5: return "Amante de las historias"
        case .badgeReading5Desc: return "Completa 5 lecturas"
        case .badgeReadingMaster: return "Maestro de la lectura"
        case .badgeReadingMasterDesc: return "30 minutos de lectura"
        case .badgeFullChapter: return "D\u{00ED}a completo"
        case .badgeFullChapterDesc: return "Completa mates + lectura en un mismo d\u{00ED}a"
        case .todaysMission: return "Misi\u{00F3}n de hoy"
        case .missionComplete: return "\u{00A1}Misi\u{00F3}n completada!"
        case .mathProgress: return "Mates"
        case .readingProgress: return "Lectura"
        case .start: return "EMPEZAR"
        case .greatJobMath: return "\u{00A1}Buen trabajo!"
        case .nowLetsRead: return "Ahora vamos a leer"
        case .continueToReading: return "Continuar"
        case .missionBonusTitle: return "\u{00A1}Bono de misi\u{00F3}n!"
        case .missionBonusDesc: return "Hoy completaste mates + lectura"
        case .yourName: return "Tu nombre"
        case .whosPlaying: return "\u{00BF}Qui\u{00E9}n est\u{00E1} jugando?"
        case .iAm: return "Soy"
        case .extraModes: return "Desaf\u{00ED}os extra"
        case .fullMissionComplete: return "\u{00A1}Misi\u{00F3}n completa terminada!"
        case .mathDone: return "Mates hechas"
        case .readingDone2: return "Lectura hecha"
        case .bonusEarned: return "Bono ganado"
        case .missionStreak: return "Racha de misiones"
        case .finishMissionToUnlockChallenges: return "Completa la mision de hoy para desbloquear desafios"
        case .finishMathToUnlockChallenges: return "Completa las mates de hoy para desbloquear desafios"
        case .language: return "Idioma"
        case .languageSystem: return "Predeterminado del sistema"
        case .languageEnglish: return "Ingl\u{00E9}s"
        case .languageNorwegian: return "Noruego"
        case .languageSpanish: return "Espa\u{00F1}ol"
        case .languagePortuguese: return "Portugu\u{00E9}s"
        case .mathPractice: return "Qu\u{00E9} practicar"
        case .recommendedForAge: return "\u{00A1}Recomendado para tu edad!"
        case .iCloudSync: return "Sincronizaci\u{00F3}n con iCloud"
        case .iCloudSyncDesc: return "Sincroniza entre tus dispositivos"
        case .iCloudNotAvailable: return "Inicia sesi\u{00F3}n en iCloud en Ajustes"
        case .synced: return "Sincronizado"
        case .challengeTimeLeft: return "Tiempo restante para jugar"
        case .challengesClosed: return "\u{00A1}Desaf\u{00ED}os cerrados!"
        case .seeYouTomorrow: return "Nos vemos ma\u{00F1}ana"
        case .changeProfile: return "Cambiar"
        case .add: return "Agregar"
        case .evenNumber: return "Par"
        case .oddNumber: return "Impar"
        case .topicNumbers: return "N\u{00FA}meros"
        case .topicAddSubBasic: return "Sumar y restar"
        case .topicStrategies: return "Estrategias"
        case .topicTensCrossing: return "Cruzar decenas"
        case .topicTimeAndCalendar: return "Hora y calendario"
        case .topicLargerNumbers: return "N\u{00FA}meros grandes"
        case .topicAddSubAdvanced: return "Mates avanzadas"
        case .topicProblemSolving: return "Resoluci\u{00F3}n de problemas"
        case .topicMeasurement: return "Medidas"
        case .topicLogicPatterns: return "L\u{00F3}gica y patrones"
        case .topicProgress: return "Progreso por temas"
        case .topicLocked: return "Bloqueado"
        case .topicCurrent: return "Actual"
        case .speechRecognitionUnavailable: return "El reconocimiento de voz no est\u{00E1} disponible"
        case .audioSessionError: return "Error de sesi\u{00F3}n de audio"
        case .audioEngineStartError: return "No se pudo iniciar el motor de audio"
        }
    }

    private static func portuguese(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "Bem-vindo ao Geni!"
        case .welcomeSubtitle: return "Aprender \u{00E9} uma aventura"
        case .createMyGeni: return "Criar o meu pr\u{00F3}prio Geni"
        case .createProfile: return "Criar perfil"
        case .nickname: return "Alcunha"
        case .nicknamePlaceholder: return "O teu nome"
        case .age: return "Idade"
        case .chooseAvatar: return "Escolher avatar"
        case .letsGo: return "Vamos!"
        case .cancel: return "Cancelar"
        case .next: return "Seguinte"
        case .done: return "Concluir"
        case .todaysChapter: return "Cap\u{00ED}tulo de hoje"
        case .specialChapter: return "Desafio especial"
        case .startChapter: return "Come\u{00E7}ar"
        case .continueChapter: return "Continuar"
        case .chapterComplete: return "Cap\u{00ED}tulo conclu\u{00ED}do!"
        case .greatJob: return "Muito bem!"
        case .keepGoing: return "Continua!"
        case .almostThere: return "Quase!"
        case .tryAgain: return "Tenta outra vez!"
        case .niceJob: return "Bom trabalho!"
        case .youGotIt: return "Acertaste!"
        case .letsKeepGoing: return "Vamos continuar!"
        case .correct: return "Correto!"
        case .showAnswer: return "Mostrar resposta"
        case .exercise: return "Exerc\u{00ED}cio"
        case .of20: return "de 20"
        case .stars: return "Estrelas"
        case .coins: return "Moedas"
        case .streak: return "Sequ\u{00EA}ncia"
        case .day: return "dia"
        case .days: return "dias"
        case .level: return "N\u{00ED}vel"
        case .xp: return "XP"
        case .addition: return "Adi\u{00E7}\u{00E3}o"
        case .subtraction: return "Subtra\u{00E7}\u{00E3}o"
        case .multiplication: return "Multiplica\u{00E7}\u{00E3}o"
        case .division: return "Divis\u{00E3}o"
        case .settings: return "Defini\u{00E7}\u{00F5}es"
        case .parentArea: return "\u{00C1}rea dos pais"
        case .enterPin: return "Inserir PIN"
        case .setPin: return "Definir PIN"
        case .changePin: return "Alterar PIN"
        case .contactSupport: return "Fale conosco"
        case .operations: return "Opera\u{00E7}\u{00F5}es"
        case .profiles: return "Perfis"
        case .addProfile: return "Adicionar perfil"
        case .editProfile: return "Editar perfil"
        case .deleteProfile: return "Eliminar perfil"
        case .progressMap: return "Progresso"
        case .rewards: return "Recompensas"
        case .badges: return "Ins\u{00ED}gnias"
        case .chapter: return "Cap\u{00ED}tulo"
        case .completed: return "Conclu\u{00ED}do"
        case .notStarted: return "N\u{00E3}o iniciado"
        case .perfectScore: return "Perfeito!"
        case .coinsEarned: return "Moedas ganhas"
        case .xpEarned: return "XP ganho"
        case .starsEarned: return "Estrelas ganhas"
        case .newBadge: return "Nova ins\u{00ED}gnia!"
        case .chapterOf: return "Cap\u{00ED}tulo"
        case .timeAttack: return "Contra o tempo"
        case .perfectRun: return "Ronda perfeita"
        case .bossChapter: return "Cap\u{00ED}tulo chefe"
        case .streakBonus: return "B\u{00F3}nus de sequ\u{00EA}ncia"
        case .spotlightChapter: return "Destaque"
        case .noChapterToday: return "Tudo feito por hoje!"
        case .comeBackTomorrow: return "Volta amanh\u{00E3}"
        case .chaptersCompleted: return "Cap\u{00ED}tulos"
        case .totalCorrect: return "Corretas"
        case .currentStreak: return "Sequ\u{00EA}ncia atual"
        case .bestLevel: return "N\u{00ED}vel"
        case .parentSettings: return "Defini\u{00E7}\u{00F5}es dos pais"
        case .childAge: return "Idade da crian\u{00E7}a"
        case .enabledOperations: return "Opera\u{00E7}\u{00F5}es ativas"
        case .recommended: return "Recomendado"
        case .custom: return "Personalizado"
        case .pin: return "PIN"
        case .pinDescription: return "Impede as crian\u{00E7}as de aceder \u{00E0}s configura\u{00E7}\u{00F5}es dos pais"
        case .pinRequired: return "Insere o teu PIN de 4 d\u{00ED}gitos"
        case .wrongPin: return "PIN incorreto"
        case .badgeFirstChapter: return "Primeiros passos"
        case .badgeFirstChapterDesc: return "Conclui o teu primeiro cap\u{00ED}tulo"
        case .badgeStreak3: return "Em grande"
        case .badgeStreak3Desc: return "Sequ\u{00EA}ncia de 3 dias"
        case .badgeStreak7: return "Guerreiro da semana"
        case .badgeStreak7Desc: return "Sequ\u{00EA}ncia de 7 dias"
        case .badgeChapters10: return "Leitor dedicado"
        case .badgeChapters10Desc: return "Conclui 10 cap\u{00ED}tulos"
        case .badgePerfect: return "Perfeito"
        case .badgePerfectDesc: return "Consegue 3 estrelas num cap\u{00ED}tulo"
        case .badgeFastSolver: return "Resolvedor r\u{00E1}pido"
        case .badgeFastSolverDesc: return "15+ respostas certas \u{00E0} primeira"
        case .badgeMulMaster: return "Mestre da multiplica\u{00E7}\u{00E3}o"
        case .badgeMulMasterDesc: return "Usa a multiplica\u{00E7}\u{00E3}o"
        case .badgeCorrect100: return "Centena"
        case .badgeCorrect100Desc: return "100 respostas corretas"
        case .badgeStreak14: return "Dedicado"
        case .badgeStreak14Desc: return "Sequ\u{00EA}ncia de 14 dias"
        case .badgeStreak30: return "Campe\u{00E3}o"
        case .badgeStreak30Desc: return "Sequ\u{00EA}ncia de 30 dias"
        case .total: return "Total"
        case .selectProfile: return "Quem vai jogar?"
        case .dailyChapter: return "Cap\u{00ED}tulo di\u{00E1}rio"
        case .specialChallenge: return "Desafio especial"
        case .clear: return "Limpar"
        case .delete: return "Eliminar"
        case .levelUp: return "Subiste de n\u{00ED}vel!"
        case .awesome: return "Incr\u{00ED}vel!"
        case .trueLabel: return "Verdadeiro"
        case .falseLabel: return "Falso"
        case .whichIsBigger: return "Qual \u{00E9} maior?"
        case .howMany: return "Quantos h\u{00E1}?"
        case .howManyTotal: return "Quantos h\u{00E1} ao todo?"
        case .whichHasMore: return "Qual tem mais?"
        case .matchConnectInstruction: return "Desenha linhas para ligar as caixas."
        case .matchThePairs: return "Liga os pares"
        case .whatComesNext: return "O que vem a seguir?"
        case .or: return "ou"
        case .timeUp: return "O tempo acabou!"
        case .reminders: return "Lembretes"
        case .dailyReminder: return "Lembrete di\u{00E1}rio"
        case .reminderTime: return "Hora do lembrete"
        case .reminderBody: return "Est\u{00E1} na hora do cap\u{00ED}tulo de matem\u{00E1}tica de hoje!"
        case .cloudSync: return "Sincroniza\u{00E7}\u{00E3}o na nuvem"
        case .syncCode: return "C\u{00F3}digo de sincroniza\u{00E7}\u{00E3}o"
        case .syncCodeDesc: return "Usa este c\u{00F3}digo para restaurar noutro dispositivo"
        case .syncNow: return "Sincronizar agora"
        case .restore: return "Restaurar"
        case .lastSync: return "Última sincronização"
        case .enterSyncCode: return "Inserir c\u{00F3}digo de sincroniza\u{00E7}\u{00E3}o"
        case .enterSyncCodeDesc: return "Insere o c\u{00F3}digo de 6 caracteres do teu outro dispositivo"
        case .adaptiveDifficulty: return "Dificuldade adaptativa"
        case .adaptiveDifficultyDesc: return "Ajusta a dificuldade com base no desempenho"
        case .premium: return "Premium"
        case .progress: return "Progresso"
        case .accuracy: return "Precis\u{00E3}o"
        case .totalXP: return "XP total"
        case .recentChapters: return "Cap\u{00ED}tulos recentes"
        case .noChaptersYet: return "Ainda n\u{00E3}o h\u{00E1} cap\u{00ED}tulos"
        case .today: return "Hoje"
        case .yesterday: return "Ontem"
        case .back: return "Voltar"
        case .readingTime: return "Tempo de leitura"
        case .readingComplete: return "Leitura conclu\u{00ED}da!"
        case .readByMyself: return "Ler sozinho"
        case .readToMe: return "L\u{00EA} para mim"
        case .listenToMeRead: return "Ouve-me ler"
        case .readBySelfDesc: return "Segue as palavras destacadas"
        case .readToMeDesc: return "A app l\u{00EA} em voz alta"
        case .listenToMeDesc: return "L\u{00EA} em voz alta e recebe feedback"
        case .minutes: return "min"
        case .pause: return "Pausar"
        case .play: return "Reproduzir"
        case .micPermissionNeeded: return "O acesso ao microfone \u{00E9} necess\u{00E1}rio"
        case .amazingReading: return "Leitura incr\u{00ED}vel!"
        case .dailyBonusTitle: return "B\u{00F3}nus di\u{00E1}rio por completar o cap\u{00ED}tulo!"
        case .dailyBonusDesc: return "Matem\u{00E1}tica + leitura conclu\u{00ED}das hoje"
        case .mathComplete: return "Matem\u{00E1}tica"
        case .readingSection: return "Leitura"
        case .startReading: return "Come\u{00E7}ar leitura"
        case .readingDone: return "Leitura conclu\u{00ED}da!"
        case .mathAndReading: return "Matem\u{00E1}tica e leitura"
        case .mathOnly: return "Matem\u{00E1}tica"
        case .optionalLabel: return "(opcional)"
        case .theme: return "Tema"
        case .themeStandard: return "Padr\u{00E3}o"
        case .themeOcean: return "Oceano"
        case .themeBlossom: return "Florescer"
        case .badgeFirstReading: return "Primeira leitura"
        case .badgeFirstReadingDesc: return "Conclui a tua primeira leitura"
        case .badgeReading5: return "Amigo das hist\u{00F3}rias"
        case .badgeReading5Desc: return "Conclui 5 leituras"
        case .badgeReadingMaster: return "Mestre da leitura"
        case .badgeReadingMasterDesc: return "30 minutos de leitura"
        case .badgeFullChapter: return "Dia completo"
        case .badgeFullChapterDesc: return "Conclui matem\u{00E1}tica + leitura no mesmo dia"
        case .todaysMission: return "Miss\u{00E3}o de hoje"
        case .missionComplete: return "Miss\u{00E3}o conclu\u{00ED}da!"
        case .mathProgress: return "Matem\u{00E1}tica"
        case .readingProgress: return "Leitura"
        case .start: return "COME\u{00C7}AR"
        case .greatJobMath: return "Bom trabalho!"
        case .nowLetsRead: return "Agora vamos ler"
        case .continueToReading: return "Continuar"
        case .missionBonusTitle: return "B\u{00F3}nus de miss\u{00E3}o!"
        case .missionBonusDesc: return "Completaste matem\u{00E1}tica + leitura hoje"
        case .yourName: return "O teu nome"
        case .whosPlaying: return "Quem est\u{00E1} a jogar?"
        case .iAm: return "Eu sou"
        case .extraModes: return "Desafios extra"
        case .fullMissionComplete: return "Miss\u{00E3}o completa conclu\u{00ED}da!"
        case .mathDone: return "Matem\u{00E1}tica conclu\u{00ED}da"
        case .readingDone2: return "Leitura conclu\u{00ED}da"
        case .bonusEarned: return "B\u{00F3}nus ganho"
        case .missionStreak: return "Sequ\u{00EA}ncia de miss\u{00F5}es"
        case .finishMissionToUnlockChallenges: return "Conclui a missao de hoje para desbloquear desafios"
        case .finishMathToUnlockChallenges: return "Conclui a matematica de hoje para desbloquear desafios"
        case .language: return "Idioma"
        case .languageSystem: return "Padr\u{00E3}o do sistema"
        case .languageEnglish: return "Ingl\u{00EA}s"
        case .languageNorwegian: return "Noruegu\u{00EA}s"
        case .languageSpanish: return "Espanhol"
        case .languagePortuguese: return "Português"
        case .mathPractice: return "O que praticar"
        case .recommendedForAge: return "Recomendado para a tua idade!"
        case .iCloudSync: return "Sincroniza\u{00E7}\u{00E3}o com iCloud"
        case .iCloudSyncDesc: return "Sincroniza entre os teus dispositivos"
        case .iCloudNotAvailable: return "Inicia sess\u{00E3}o no iCloud nos Ajustes"
        case .synced: return "Sincronizado"
        case .challengeTimeLeft: return "Tempo restante para jogar"
        case .challengesClosed: return "Desafios encerrados!"
        case .seeYouTomorrow: return "At\u{00E9} amanh\u{00E3}"
        case .changeProfile: return "Mudar"
        case .add: return "Adicionar"
        case .evenNumber: return "Par"
        case .oddNumber: return "Ímpar"
        case .topicNumbers: return "N\u{00FA}meros"
        case .topicAddSubBasic: return "Somar e subtrair"
        case .topicStrategies: return "Estrat\u{00E9}gias"
        case .topicTensCrossing: return "Passagem da dezena"
        case .topicTimeAndCalendar: return "Tempo e calend\u{00E1}rio"
        case .topicLargerNumbers: return "N\u{00FA}meros maiores"
        case .topicAddSubAdvanced: return "Matem\u{00E1}tica avan\u{00E7}ada"
        case .topicProblemSolving: return "Resolu\u{00E7}\u{00E3}o de problemas"
        case .topicMeasurement: return "Medi\u{00E7}\u{00E3}o"
        case .topicLogicPatterns: return "L\u{00F3}gica e padr\u{00F5}es"
        case .topicProgress: return "Progresso por temas"
        case .topicLocked: return "Bloqueado"
        case .topicCurrent: return "Atual"
        case .speechRecognitionUnavailable: return "O reconhecimento de fala n\u{00E3}o est\u{00E1} dispon\u{00ED}vel"
        case .audioSessionError: return "Erro na sess\u{00E3}o de \u{00E1}udio"
        case .audioEngineStartError: return "N\u{00E3}o foi poss\u{00ED}vel iniciar o motor de \u{00E1}udio"
        }
    }
}
