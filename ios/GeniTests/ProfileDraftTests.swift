import Foundation
import SwiftUI
import Testing
@testable import Geni

@MainActor
struct ProfileDraftTests {

    // MARK: - Create

    @Test func newDraftUsesDefaultsNotTheActiveChildsLook() {
        ThemeManager.shared.current = .blossom
        ThemeManager.shared.cornerStyle = .rounded
        defer {
            ThemeManager.shared.current = .standard
            ThemeManager.shared.cornerStyle = .sharp
        }

        let draft = ProfileDraft(existingNames: ["Ada"])
        #expect(draft.theme == .standard)
        #expect(draft.cornerStyle == .sharp)
        #expect(draft.age == 6)
        #expect(draft.avatarId == "lion")
        #expect(draft.operations == Set(MathOperation.recommended(for: 6)))
        #expect(draft.readingEnabled)
        #expect(!draft.isEditing)
    }

    @Test func applyBuildsANewProfileFromTheDraft() {
        let draft = ProfileDraft()
        draft.nickname = "  Bo  "
        draft.setAge(8)
        draft.selectAvatar("robot")
        draft.theme = .ocean
        draft.cornerStyle = .rounded
        draft.toggle(.division)

        let profile = draft.apply()
        #expect(profile.nickname == "Bo")
        #expect(profile.age == 8)
        #expect(profile.avatarId == "robot")
        #expect(profile.theme == .ocean)
        #expect(profile.cornerStyle == .rounded)
        #expect(Set(profile.operationsEnabled) == [.addition, .subtraction, .multiplication, .division])
        #expect(profile.readingEnabled == true)
    }

    @Test func savingAndCreatingDoesNotTouchTheGlobalTheme() {
        ThemeManager.shared.current = .standard
        ThemeManager.shared.cornerStyle = .sharp
        let draft = ProfileDraft()
        draft.theme = .blossom
        draft.cornerStyle = .rounded
        _ = draft.profile
        #expect(ThemeManager.shared.current == .standard)
        #expect(ThemeManager.shared.cornerStyle == .sharp)
    }

    // MARK: - Edit

    @Test func editingKeepsIdentityAndCustomOperations() {
        var bo = ChildProfile(nickname: "Bo", age: 8, avatarId: "astronaut")
        bo.operationsEnabled = [.addition, .division]
        bo.theme = .ocean
        bo.cornerStyle = .rounded
        bo.remindersEnabled = true

        let draft = ProfileDraft(editing: bo, existingNames: ["Ada"])
        #expect(draft.isEditing)
        #expect(draft.operations == [.addition, .division])
        #expect(draft.cornerStyle == .rounded)
        #expect(draft.theme == .ocean)

        draft.theme = .blossom
        let saved = draft.profile
        #expect(saved.id == bo.id)
        #expect(saved.createdAt == bo.createdAt)
        #expect(saved.remindersEnabled)
        #expect(Set(saved.operationsEnabled) == [.addition, .division])
        #expect(saved.theme == .blossom)
        #expect(saved.cornerStyle == .rounded)
    }

    @Test func legacyProfileWithoutCornerStyleEditsAsSharp() {
        let old = ChildProfile(nickname: "Cy", age: 7, avatarId: "lion")
        #expect(old.cornerStyle == nil)
        let draft = ProfileDraft(editing: old)
        #expect(draft.cornerStyle == .sharp)
        draft.cornerStyle = .rounded
        #expect(draft.profile.cornerStyle == .rounded)
    }

    @Test func ageSixReadingSwitchIsSaved() {
        let ada = ChildProfile(nickname: "Ada", age: 6, avatarId: "lion")
        let draft = ProfileDraft(editing: ada)
        draft.readingEnabled = false
        let saved = draft.profile
        #expect(saved.readingEnabled == false)
        #expect(saved.readingMode == .hidden)
    }

    // MARK: - Age

    @Test func setAgeResetsOperationsOnlyWhenTheAgeChanges() {
        var bo = ChildProfile(nickname: "Bo", age: 8, avatarId: "robot")
        bo.operationsEnabled = [.addition, .division]
        let draft = ProfileDraft(editing: bo)

        draft.setAge(8)
        #expect(draft.operations == [.addition, .division], "re-tapping the same age must keep custom operations")

        draft.setAge(5)
        #expect(draft.age == 5)
        #expect(draft.operations == Set(MathOperation.recommended(for: 5)))
        #expect(draft.isRecommended(.addition))
        #expect(!draft.isRecommended(.division))
    }

    @Test func toggleKeepsAtLeastOneOperation() {
        let draft = ProfileDraft()
        draft.setAge(5)
        #expect(draft.operations == [.addition])
        draft.toggle(.addition)
        #expect(draft.operations == [.addition])
        draft.toggle(.subtraction)
        draft.toggle(.addition)
        #expect(draft.operations == [.subtraction])
    }

    // MARK: - Names

    @Test func nameValidation() {
        let draft = ProfileDraft(existingNames: ["Ada", " Bo "])
        #expect(!draft.canSave)
        draft.nickname = "   "
        #expect(!draft.hasName && !draft.canSave)
        draft.nickname = "ada"
        #expect(draft.isDuplicate && !draft.canSave)
        draft.nickname = "bo"
        #expect(draft.isDuplicate)
        draft.nickname = "Cy"
        #expect(!draft.isDuplicate && draft.canSave)
    }

    // MARK: - Avatars

    @Test func catalogIdsAreUnchangedAndNeverBlack() {
        let starters = ["lion", "unicorn", "robot", "rocket", "dragon", "dino", "penguin", "fox", "panda", "alien", "octopus", "monkey"]
        let extras = ["cat", "dog", "bear", "frog", "butterfly", "dolphin", "owl", "bee", "star", "rainbow", "sun", "flower",
                      "wizard", "fairy", "superhero", "astronaut"]
        #expect(AvatarOption.all.map(\.id) == starters)
        #expect(AvatarOption.extras.map(\.id) == extras)
        #expect(AvatarOption.catalog.map(\.id) == starters + extras)
        #expect(Set(AvatarOption.catalog.map(\.id)).count == 28)
        for avatar in AvatarOption.catalog {
            #expect(avatar.color != .black, "\(avatar.id) is black")
        }
        #expect(AvatarOption.find("unknown").id == "lion")
    }

    @Test func quickPicksNeverGrowANinthTile() {
        let base = AvatarOption.all.prefix(7).map(\.id)
        #expect(AvatarOption.quickPicks(selected: "lion").map(\.id) == base)

        let withCat = AvatarOption.quickPicks(selected: "cat").map(\.id)
        #expect(withCat.count == 7)
        #expect(Array(withCat.prefix(6)) == Array(base.prefix(6)))
        #expect(withCat[6] == "cat", "a selected extra replaces slot 7")

        // A starter outside the first seven also counts as an extra.
        #expect(AvatarOption.quickPicks(selected: "monkey").map(\.id)[6] == "monkey")
    }

    @Test func pickedExtraStaysInSlotSevenAfterChoosingAQuickAvatar() {
        let draft = ProfileDraft()
        draft.selectAvatar("wizard")
        #expect(draft.quickAvatars.map(\.id)[6] == "wizard")
        draft.selectAvatar("robot")
        #expect(draft.avatarId == "robot")
        #expect(draft.quickAvatars.count == 7)
        #expect(draft.quickAvatars.map(\.id)[6] == "wizard")
        draft.selectAvatar("fairy")
        #expect(draft.quickAvatars.map(\.id)[6] == "fairy")
    }

    @Test func editingAProfileWithAnExtraShowsItInTheQuickGrid() {
        let draft = ProfileDraft(editing: ChildProfile(nickname: "Di", age: 7, avatarId: "astronaut"))
        #expect(draft.quickAvatars.map(\.id)[6] == "astronaut")
    }

    @Test func cornerStyleRadius() {
        #expect(CornerStyle.sharp.radius == 0)
        #expect(CornerStyle.rounded.radius > 0)
        let draft = ProfileDraft()
        draft.cornerStyle = .rounded
        #expect(draft.cornerRadius == CornerStyle.rounded.radius)
    }
}
