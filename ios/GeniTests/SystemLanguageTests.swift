import Testing
@testable import Geni

/// The app follows the iPhone's language list: first supported language wins, English otherwise.
struct SystemLanguageTests {
    @Test func picksFirstSupportedPreferredLanguage() {
        #expect(LanguageManager.language(forPreferred: ["nb-NO", "en-US"]) == .norwegian)
        #expect(LanguageManager.language(forPreferred: ["nn-NO"]) == .norwegian)
        #expect(LanguageManager.language(forPreferred: ["de-DE", "nb-NO"]) == .norwegian)
        #expect(LanguageManager.language(forPreferred: ["es-MX"]) == .spanish)
        #expect(LanguageManager.language(forPreferred: ["pt-BR", "es-ES"]) == .portuguese)
        #expect(LanguageManager.language(forPreferred: ["en-GB", "nb-NO"]) == .english)
    }

    @Test func fallsBackToEnglish() {
        #expect(LanguageManager.language(forPreferred: ["de-DE", "fr-FR"]) == .english)
        #expect(LanguageManager.language(forPreferred: []) == .english)
    }
}
