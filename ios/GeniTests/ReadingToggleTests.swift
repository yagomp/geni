import Foundation
import Testing
@testable import Geni

struct ReadingToggleTests {

    @Test func ageSixReadsByDefault() {
        let profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        #expect(profile.readingMode == .optional)
    }

    @Test func parentCanTurnReadingOffForAgeSix() {
        var profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        profile.readingEnabled = false
        #expect(profile.readingMode == .hidden)
        profile.readingEnabled = true
        #expect(profile.readingMode == .optional)
    }

    @Test func switchOnlyAffectsAgeSix() {
        var older = ChildProfile(nickname: "Bo", age: 8, avatarId: "lion")
        older.readingEnabled = false
        #expect(older.readingMode == .required)
    }

    @Test func savedProfilesWithoutTheSwitchStillDecode() throws {
        var profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        profile.readingEnabled = nil
        let data = try JSONEncoder().encode(profile)
        #expect(String(decoding: data, as: UTF8.self).contains("readingEnabled") == false)
        let decoded = try JSONDecoder().decode(ChildProfile.self, from: data)
        #expect(decoded.readingEnabled == nil)
        #expect(decoded.readingMode == .optional)
    }
}

struct CornerStyleTests {
    @Test func olderProfilesStaySharp() throws {
        var profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        profile.cornerStyle = nil
        let decoded = try JSONDecoder().decode(ChildProfile.self, from: JSONEncoder().encode(profile))
        #expect(decoded.cornerStyle == nil)
        ThemeManager.shared.apply(decoded)
        #expect(ThemeManager.shared.cornerRadius == 0)
    }

    @Test func roundedProfileRoundsCorners() {
        var profile = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        profile.cornerStyle = .rounded
        ThemeManager.shared.apply(profile)
        #expect(ThemeManager.shared.cornerRadius > 0)
        ThemeManager.shared.cornerStyle = .sharp
    }
}
