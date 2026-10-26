import SwiftUI

/// All editable profile fields for creation and editing. Nothing is persisted until the caller
/// receives `apply(to:)`'s result; the global ThemeManager is never touched.
@Observable
final class ProfileDraft {
    var nickname: String
    private(set) var age: Int
    private(set) var avatarId: String
    /// Last avatar picked from the full chooser that isn't a quick pick; keeps slot 7.
    private(set) var pinnedAvatarId: String?
    var operations: Set<MathOperation>
    var theme: AppTheme
    var readingEnabled: Bool
    let existingNames: [String]
    let original: ChildProfile?

    static let ages = 4...10

    /// A new profile starts from defaults — never from the active child's theme.
    init(editing profile: ChildProfile? = nil, existingNames: [String] = []) {
        original = profile
        self.existingNames = existingNames
        nickname = profile?.nickname ?? ""
        age = profile?.age ?? 6
        avatarId = profile?.avatarId ?? AvatarOption.all[0].id
        operations = Set(profile?.operationsEnabled ?? MathOperation.recommended(for: profile?.age ?? 6))
        theme = profile?.theme ?? .standard
        readingEnabled = profile?.readingEnabled ?? true
        pinnedAvatarId = nil
        if let profile { pin(profile.avatarId) }
    }

    var isEditing: Bool { original != nil }

    var trimmedName: String { nickname.trimmingCharacters(in: .whitespacesAndNewlines) }
    var hasName: Bool { !trimmedName.isEmpty }

    var isDuplicate: Bool {
        let name = trimmedName.lowercased()
        return !name.isEmpty && existingNames.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name }
    }

    var canSave: Bool { hasName && !isDuplicate }

    /// A user tap on an age chip: a real change resets operations to the recommended set.
    func setAge(_ newAge: Int) {
        guard newAge != age else { return }
        age = newAge
        operations = Set(MathOperation.recommended(for: newAge))
    }

    func selectAvatar(_ id: String) {
        avatarId = id
        pin(id)
    }

    private func pin(_ id: String) {
        if !AvatarOption.all.prefix(AvatarOption.quickCount).contains(where: { $0.id == id }) {
            pinnedAvatarId = id
        }
    }

    var quickAvatars: [AvatarOption] {
        AvatarOption.quickPicks(selected: avatarId, pinned: pinnedAvatarId)
    }

    /// Toggles an operation, keeping at least one selected.
    func toggle(_ op: MathOperation) {
        if operations.contains(op) {
            if operations.count > 1 { operations.remove(op) }
        } else {
            operations.insert(op)
        }
    }

    func isRecommended(_ op: MathOperation) -> Bool {
        MathOperation.recommended(for: age).contains(op)
    }

    /// The draft written onto `base` (keeping its id and other fields), or a new profile.
    func apply(to base: ChildProfile? = nil) -> ChildProfile {
        var profile = base ?? ChildProfile(nickname: trimmedName, age: age, avatarId: avatarId)
        profile.nickname = trimmedName
        profile.age = age
        profile.avatarId = avatarId
        profile.operationsEnabled = MathOperation.allCases.filter(operations.contains)
        profile.theme = theme
        profile.readingEnabled = readingEnabled
        return profile
    }

    /// The edited profile, or a new one when creating.
    var profile: ChildProfile { apply(to: original) }

    // MARK: Local preview (never the global ThemeManager)

    var screenBackground: Color { theme.previewBackground }
}

extension AppTheme {
    /// Matches `ThemeManager.screenBackground` for this theme.
    var previewBackground: Color {
        switch self {
        case .standard: return Color(red: 1.0, green: 0.97, blue: 0.88)
        case .ocean: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .blossom: return Color(red: 1.0, green: 0.93, blue: 0.95)
        }
    }

    /// The theme's signature colour (yellow for standard).
    var previewSwatch: Color {
        switch self {
        case .standard: return GeniColor.yellow
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }

    /// Matches `ThemeManager.accent` for this theme.
    var previewAccent: Color {
        switch self {
        case .standard: return Color(red: 0.0, green: 0.4, blue: 1.0)
        case .ocean: return Color(red: 0.18, green: 0.45, blue: 0.82)
        case .blossom: return Color(red: 0.88, green: 0.28, blue: 0.48)
        }
    }

    var displayName: String {
        switch self {
        case .standard: return L.s(.themeStandard)
        case .ocean: return L.s(.themeOcean)
        case .blossom: return L.s(.themeBlossom)
        }
    }
}
