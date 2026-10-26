import Foundation
import Security

@Observable
@MainActor
class PersistenceService {
    private let profilesKey = "geni_profiles"
    private let rewardsKeyPrefix = "geni_rewards_"
    private let chaptersKeyPrefix = "geni_chapters_"
    private let pinKeychainKey = "com.yagomp.geni.parentPin"
    private let hasOnboardedKey = "geni_has_onboarded"
    private let activeProfileKey = "geni_active_profile"
    private let readingKeyPrefix = "geni_reading_"
    private let topicProgressKeyPrefix = "geni_topics_"
    private let deletedProfilesKey = "geni_deleted_profiles"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var profiles: [ChildProfile] = []
    var hasOnboarded: Bool = false
    var parentPin: String? = nil
    var activeProfileId: String? = nil

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadAll()
    }

    func loadAll() {
        hasOnboarded = defaults.bool(forKey: hasOnboardedKey)
        activeProfileId = defaults.string(forKey: activeProfileKey)
        parentPin = loadPinFromKeychain()

        // Migrate plaintext PIN from UserDefaults to Keychain
        if parentPin == nil, let legacyPin = defaults.string(forKey: "geni_parent_pin") {
            parentPin = legacyPin
            savePinToKeychain(legacyPin)
            defaults.removeObject(forKey: "geni_parent_pin")
        }

        if let data = defaults.data(forKey: profilesKey),
           let decoded = try? decoder.decode([ChildProfile].self, from: data) {
            profiles = decoded
        }
    }

    func completeOnboarding() {
        hasOnboarded = true
        defaults.set(true, forKey: hasOnboardedKey)
    }

    func saveProfile(_ profile: ChildProfile) {
        var profile = profile
        // An explicit empty focus can sync a clear; a missing key belongs to older clients.
        profile.focusGames = profile.focusGames ?? []
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        persistProfiles()

        if profiles.count == 1 {
            setActiveProfile(profile.id)
        }
    }

    func deleteProfile(_ id: String) {
        profiles.removeAll { $0.id == id }
        persistProfiles()
        removeChildData(for: id)
        var deleted = deletedProfileIds
        deleted.insert(id)
        defaults.set(Array(deleted).sorted(), forKey: deletedProfilesKey)
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
            defaults.set(activeProfileId, forKey: activeProfileKey)
        }
    }

    /// Back to a fresh install: every child is deleted (and tombstoned, so iCloud drops them too),
    /// onboarding starts over and the PIN is removed.
    func resetAll(alsoDeleting otherIds: Set<String> = []) {
        var deleted = deletedProfileIds.union(otherIds)
        for profile in profiles {
            removeChildData(for: profile.id)
            deleted.insert(profile.id)
        }
        defaults.set(Array(deleted).sorted(), forKey: deletedProfilesKey)
        profiles = []
        persistProfiles()
        activeProfileId = nil
        defaults.removeObject(forKey: activeProfileKey)
        hasOnboarded = false
        defaults.set(false, forKey: hasOnboardedKey)
        clearPin()
    }

    /// IDs of deleted profiles, synced so other devices drop them too.
    var deletedProfileIds: Set<String> {
        Set(defaults.stringArray(forKey: deletedProfilesKey) ?? [])
    }

    private func removeChildData(for childId: String) {
        for prefix in [rewardsKeyPrefix, chaptersKeyPrefix, readingKeyPrefix, topicProgressKeyPrefix] {
            defaults.removeObject(forKey: prefix + childId)
        }
    }

    func setActiveProfile(_ id: String) {
        activeProfileId = id
        defaults.set(id, forKey: activeProfileKey)
    }

    var activeProfile: ChildProfile? {
        profiles.first { $0.id == activeProfileId }
    }

    func setPin(_ pin: String) {
        parentPin = pin
        savePinToKeychain(pin)
    }

    func clearPin() {
        parentPin = nil
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    func verifyPin(_ pin: String) -> Bool {
        parentPin == pin
    }

    // MARK: - Keychain

    private func savePinToKeychain(_ pin: String) {
        let data = Data(pin.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadPinFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveRewardState(_ state: RewardState, for childId: String) {
        if let data = try? encoder.encode(state) {
            defaults.set(data, forKey: rewardsKeyPrefix + childId)
        }
    }

    func loadRewardState(for childId: String) -> RewardState {
        guard let data = defaults.data(forKey: rewardsKeyPrefix + childId),
              let state = try? decoder.decode(RewardState.self, from: data) else {
            return RewardState()
        }
        return state
    }

    func saveChapterProgress(_ progress: ChapterProgress) {
        var all = loadAllChapters(for: progress.childId)
        if let index = all.firstIndex(where: { $0.id == progress.id }) {
            all[index] = progress
        } else {
            all.append(progress)
        }
        if let data = try? encoder.encode(all) {
            defaults.set(data, forKey: chaptersKeyPrefix + progress.childId)
        }
    }

    func loadAllChapters(for childId: String) -> [ChapterProgress] {
        guard let data = defaults.data(forKey: chaptersKeyPrefix + childId),
              let chapters = try? decoder.decode([ChapterProgress].self, from: data) else {
            return []
        }
        return chapters
    }

    func todayChapter(for childId: String) -> ChapterProgress? {
        let today = todayString()
        let chapters = loadAllChapters(for: childId).filter { $0.date == today && $0.chapterType == .daily }
        // Two devices can each start today's chapter; a completed one wins.
        return chapters.first { $0.status == .completed } ?? chapters.first
    }

    func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    func saveReadingSession(_ session: ReadingSession) {
        var all = loadAllReadingSessions(for: session.childId)
        if let index = all.firstIndex(where: { $0.id == session.id }) {
            all[index] = session
        } else {
            all.append(session)
        }
        if let data = try? encoder.encode(all) {
            defaults.set(data, forKey: readingKeyPrefix + session.childId)
        }
    }

    func loadAllReadingSessions(for childId: String) -> [ReadingSession] {
        guard let data = defaults.data(forKey: readingKeyPrefix + childId),
              let sessions = try? decoder.decode([ReadingSession].self, from: data) else {
            return []
        }
        return sessions
    }

    func todayReadingSession(for childId: String) -> ReadingSession? {
        let today = todayString()
        return loadAllReadingSessions(for: childId).first { $0.date == today && $0.isCompleted }
    }

    func saveTopicProgress(_ progress: TopicProgress, for childId: String) {
        if let data = try? encoder.encode(progress) {
            defaults.set(data, forKey: topicProgressKeyPrefix + childId)
        }
    }

    func loadTopicProgress(for childId: String) -> TopicProgress {
        guard let data = defaults.data(forKey: topicProgressKeyPrefix + childId),
              let progress = try? decoder.decode(TopicProgress.self, from: data) else {
            return TopicProgress()
        }
        return progress
    }

    // MARK: - Cloud Sync

    /// Merges a cloud snapshot into local storage. Local progress that hasn't synced yet is kept.
    func applyCloudData(
        profiles cloudProfiles: [ChildProfile],
        chapters: [String: [ChapterProgress]],
        rewards: [String: RewardState],
        readings: [String: [ReadingSession]],
        topicProgress: [String: TopicProgress] = [:],
        deletedProfileIds cloudDeleted: Set<String> = [],
        hasOnboarded cloudOnboarded: Bool
    ) {
        let deleted = deletedProfileIds.union(cloudDeleted)
        defaults.set(Array(deleted).sorted(), forKey: deletedProfilesKey)

        // Upsert profiles, honoring deletions from either side
        for cloudProfile in cloudProfiles where !deleted.contains(cloudProfile.id) {
            if let index = profiles.firstIndex(where: { $0.id == cloudProfile.id }) {
                var merged = cloudProfile
                // 1.2.0 drops unknown fields when re-saving a profile.
                merged.focusGames = cloudProfile.focusGames ?? profiles[index].focusGames
                profiles[index] = merged
            } else {
                profiles.append(cloudProfile)
            }
        }
        profiles.removeAll { deleted.contains($0.id) }
        deleted.forEach(removeChildData)
        persistProfiles()

        // Merge per-child data
        for (childId, childChapters) in chapters where !deleted.contains(childId) {
            let merged = Self.mergeById(loadAllChapters(for: childId), childChapters) { $0.isMoreProgressed(than: $1) }
            if let data = try? encoder.encode(merged) {
                defaults.set(data, forKey: chaptersKeyPrefix + childId)
            }
        }
        for (childId, childRewards) in rewards where !deleted.contains(childId) {
            saveRewardState(loadRewardState(for: childId).merged(with: childRewards), for: childId)
        }
        for (childId, childReadings) in readings where !deleted.contains(childId) {
            let merged = Self.mergeById(loadAllReadingSessions(for: childId), childReadings) { $0.isMoreProgressed(than: $1) }
            if let data = try? encoder.encode(merged) {
                defaults.set(data, forKey: readingKeyPrefix + childId)
            }
        }
        for (childId, childTopics) in topicProgress where !deleted.contains(childId) {
            saveTopicProgress(loadTopicProgress(for: childId).merged(with: childTopics), for: childId)
        }

        if profiles.isEmpty {
            // Every child was deleted elsewhere (e.g. Start over): this device starts fresh too
            hasOnboarded = false
            defaults.set(false, forKey: hasOnboardedKey)
        } else if cloudOnboarded && !hasOnboarded {
            completeOnboarding()
        }

        if activeProfile == nil, let first = profiles.first {
            setActiveProfile(first.id)
        }
    }

    /// Union by id, keeping local order; `prefersRemote(remote, local)` decides conflicts.
    static func mergeById<T: Identifiable>(
        _ local: [T],
        _ remote: [T],
        prefersRemote: (T, T) -> Bool
    ) -> [T] where T.ID == String {
        var merged = local
        for item in remote {
            if let index = merged.firstIndex(where: { $0.id == item.id }) {
                if prefersRemote(item, merged[index]) { merged[index] = item }
            } else {
                merged.append(item)
            }
        }
        return merged
    }

    private func persistProfiles() {
        if let data = try? encoder.encode(profiles) {
            defaults.set(data, forKey: profilesKey)
        }
    }
}
