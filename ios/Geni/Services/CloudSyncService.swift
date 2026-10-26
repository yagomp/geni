import Foundation

/// The slice of `NSUbiquitousKeyValueStore` used for sync, so tests can use an in-memory store.
protocol CloudKeyValueStore: AnyObject {
    func data(forKey aKey: String) -> Data?
    func set(_ aData: Data?, forKey aKey: String)
    func double(forKey aKey: String) -> Double
    func set(_ value: Double, forKey aKey: String)
    func bool(forKey aKey: String) -> Bool
    func set(_ value: Bool, forKey aKey: String)
    func removeObject(forKey aKey: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: CloudKeyValueStore {}

@Observable
@MainActor
class CloudSyncService {
    private let store: any CloudKeyValueStore
    private let defaults: UserDefaults
    private let checkICloudAvailable: () -> Bool

    private let profilesKey = "sync_profiles"
    private let chaptersPrefix = "sync_chapters_"
    private let rewardsPrefix = "sync_rewards_"
    private let readingsPrefix = "sync_readings_"
    private let topicsPrefix = "sync_topics_"
    private let deletedProfilesKey = "sync_deleted_profiles"
    private let onboardedKey = "sync_onboarded"
    private let lastModifiedKey = "sync_last_modified"
    private let syncEnabledKey = "geni_icloud_sync_enabled"
    private let lastSyncKey = "geni_last_sync"

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var isSyncing: Bool = false
    var lastSyncDate: Date? = nil
    var syncEnabled: Bool = true
    var syncError: String? = nil
    var onExternalChange: (() -> Void)? = nil

    var isICloudAvailable: Bool {
        checkICloudAvailable()
    }

    init(
        store: any CloudKeyValueStore = NSUbiquitousKeyValueStore.default,
        defaults: UserDefaults = .standard,
        isICloudAvailable: @escaping () -> Bool = { FileManager.default.ubiquityIdentityToken != nil }
    ) {
        self.store = store
        self.defaults = defaults
        self.checkICloudAvailable = isICloudAvailable
        syncEnabled = defaults.object(forKey: syncEnabledKey) as? Bool ?? true
        if let interval = defaults.object(forKey: lastSyncKey) as? Double {
            lastSyncDate = Date(timeIntervalSince1970: interval)
        }

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store as AnyObject,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleExternalChange(notification)
            }
        }

        store.synchronize()
    }

    func setSyncEnabled(_ enabled: Bool) {
        syncEnabled = enabled
        defaults.set(enabled, forKey: syncEnabledKey)
    }

    // MARK: - Push

    func pushToCloud(persistence: PersistenceService) {
        guard syncEnabled, isICloudAvailable else { return }
        isSyncing = true
        syncError = nil

        do {
            // Keep deletions made on other devices that this one hasn't pulled yet
            let deleted = persistence.deletedProfileIds.union(remoteDeletedProfileIds())
            let profiles = persistence.profiles.filter { !deleted.contains($0.id) }

            let profilesData = try encoder.encode(profiles)
            store.set(profilesData, forKey: profilesKey)
            store.set(persistence.hasOnboarded && !profiles.isEmpty, forKey: onboardedKey)
            store.set(try encoder.encode(Array(deleted).sorted()), forKey: deletedProfilesKey)
            for id in deleted {
                for prefix in [chaptersPrefix, rewardsPrefix, readingsPrefix, topicsPrefix] {
                    store.removeObject(forKey: prefix + id)
                }
            }

            // Merge with what's already in the cloud so another device's unpulled progress survives
            for profile in profiles {
                let chapters = PersistenceService.mergeById(
                    persistence.loadAllChapters(for: profile.id),
                    remote([ChapterProgress].self, forKey: chaptersPrefix + profile.id) ?? []
                ) { $0.isMoreProgressed(than: $1) }
                let chaptersData = try encoder.encode(chapters)
                store.set(chaptersData, forKey: chaptersPrefix + profile.id)

                var rewards = persistence.loadRewardState(for: profile.id)
                if let remoteRewards = remote(RewardState.self, forKey: rewardsPrefix + profile.id) {
                    rewards = rewards.merged(with: remoteRewards)
                }
                let rewardsData = try encoder.encode(rewards)
                store.set(rewardsData, forKey: rewardsPrefix + profile.id)

                let readings = PersistenceService.mergeById(
                    persistence.loadAllReadingSessions(for: profile.id),
                    remote([ReadingSession].self, forKey: readingsPrefix + profile.id) ?? []
                ) { $0.isMoreProgressed(than: $1) }
                let readingsData = try encoder.encode(readings)
                store.set(readingsData, forKey: readingsPrefix + profile.id)

                var topics = persistence.loadTopicProgress(for: profile.id)
                if let remoteTopics = remote(TopicProgress.self, forKey: topicsPrefix + profile.id) {
                    topics = topics.merged(with: remoteTopics)
                }
                store.set(try encoder.encode(topics), forKey: topicsPrefix + profile.id)
            }

            store.set(Date().timeIntervalSince1970, forKey: lastModifiedKey)
            store.synchronize()

            lastSyncDate = Date()
            defaults.set(lastSyncDate!.timeIntervalSince1970, forKey: lastSyncKey)
            isSyncing = false
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
        }
    }

    /// Profile ids currently in iCloud, including ones this device hasn't pulled.
    func remoteProfileIds() -> Set<String> {
        guard syncEnabled, isICloudAvailable else { return [] }
        store.synchronize()
        return Set((remote([ChildProfile].self, forKey: profilesKey) ?? []).map(\.id))
    }

    /// True when iCloud lacks a deletion this device made: a tombstone is missing or a deleted child is listed.
    func isMissingLocalDeletions(persistence: PersistenceService) -> Bool {
        guard syncEnabled, isICloudAvailable else { return false }
        let local = persistence.deletedProfileIds
        guard !local.isEmpty else { return false }
        if !local.isSubset(of: remoteDeletedProfileIds()) { return true }
        return remoteProfileIds().contains { local.contains($0) }
    }

    // MARK: - Pull

    /// `force` skips the timestamp check; used when iCloud reports an incoming change.
    func pullFromCloud(persistence: PersistenceService, force: Bool = false) {
        guard syncEnabled, isICloudAvailable else { return }
        store.synchronize()

        guard let profilesData = store.data(forKey: profilesKey),
              let profiles = try? decoder.decode([ChildProfile].self, from: profilesData) else { return }
        // An empty cloud only matters when it deletes children this device still has (a reset elsewhere)
        if profiles.isEmpty && remoteDeletedProfileIds().isDisjoint(with: persistence.profiles.map(\.id)) {
            return
        }

        // Only apply if local is empty (new device) or remote is newer
        let remoteTimestamp = store.double(forKey: lastModifiedKey)
        let localTimestamp = defaults.double(forKey: lastSyncKey)

        if force || persistence.profiles.isEmpty || remoteTimestamp > localTimestamp {
            applyRemoteData(persistence: persistence, profiles: profiles)
        }
    }

    // MARK: - External Change Handler

    private func handleExternalChange(_ notification: Notification) {
        guard syncEnabled else { return }

        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }

        switch reason {
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            syncError = "iCloud storage full"
            return
        case NSUbiquitousKeyValueStoreAccountChange:
            lastSyncDate = nil
            defaults.removeObject(forKey: lastSyncKey)
            return
        default:
            break
        }

        onExternalChange?()
    }

    // MARK: - Apply Remote Data

    private func applyRemoteData(persistence: PersistenceService, profiles: [ChildProfile]) {
        var chapters: [String: [ChapterProgress]] = [:]
        var rewards: [String: RewardState] = [:]
        var readings: [String: [ReadingSession]] = [:]
        var topics: [String: TopicProgress] = [:]

        for profile in profiles {
            chapters[profile.id] = remote([ChapterProgress].self, forKey: chaptersPrefix + profile.id)
            rewards[profile.id] = remote(RewardState.self, forKey: rewardsPrefix + profile.id)
            readings[profile.id] = remote([ReadingSession].self, forKey: readingsPrefix + profile.id)
            topics[profile.id] = remote(TopicProgress.self, forKey: topicsPrefix + profile.id)
        }

        let hasOnboarded = store.bool(forKey: onboardedKey)

        persistence.applyCloudData(
            profiles: profiles,
            chapters: chapters,
            rewards: rewards,
            readings: readings,
            topicProgress: topics,
            deletedProfileIds: remoteDeletedProfileIds(),
            hasOnboarded: hasOnboarded
        )

        lastSyncDate = Date()
        defaults.set(lastSyncDate!.timeIntervalSince1970, forKey: lastSyncKey)
    }

    private func remote<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func remoteDeletedProfileIds() -> Set<String> {
        Set(remote([String].self, forKey: deletedProfilesKey) ?? [])
    }
}
