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
    case language
    case languageSystem
    case languageEnglish
    case languageNorwegian
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
}

nonisolated enum AppLanguage: String, Sendable, CaseIterable {
    case english
    case norwegian

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .norwegian: return "🇳🇴"
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
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("nb") || preferred.hasPrefix("nn") || preferred.hasPrefix("no") {
                self.current = .norwegian
            } else {
                self.current = .english
            }
        }
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
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("nb") || preferred.hasPrefix("nn") || preferred.hasPrefix("no") {
            return .norwegian
        }
        return .english
    }

    static var isNorwegian: Bool {
        selectedLanguage == .norwegian
    }

    static func s(_ key: LocaleKey) -> String {
        return isNorwegian ? norwegian(key) : english(key)
    }

    static func s(_ key: LocaleKey, lang: AppLanguage) -> String {
        return lang == .norwegian ? norwegian(key) : english(key)
    }

    private static func english(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "Welcome to Geni!"
        case .welcomeSubtitle: return "Learning is fun!"
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
        case .language: return "Language"
        case .languageSystem: return "System Default"
        case .languageEnglish: return "English"
        case .languageNorwegian: return "Norwegian"
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
        }
    }

    private static func norwegian(_ key: LocaleKey) -> String {
        switch key {
        case .appName: return "Geni"
        case .welcome: return "Velkommen til Geni!"
        case .welcomeSubtitle: return "L\u{00E6}ring er g\u{00F8}y!"
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
        case .language: return "Spr\u{00E5}k"
        case .languageSystem: return "Systemstandard"
        case .languageEnglish: return "Engelsk"
        case .languageNorwegian: return "Norsk"
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
        }
    }
}
