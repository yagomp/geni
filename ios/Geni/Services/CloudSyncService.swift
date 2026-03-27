import Foundation

@Observable
@MainActor
class CloudSyncService {
    private let store = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard

    private let profilesKey = "sync_profiles"
    private let chaptersPrefix = "sync_chapters_"
    private let rewardsPrefix = "sync_rewards_"
    private let readingsPrefix = "sync_readings_"
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
        FileManager.default.ubiquityIdentityToken != nil
    }

    init() {
        syncEnabled = defaults.object(forKey: syncEnabledKey) as? Bool ?? true
        if let interval = defaults.object(forKey: lastSyncKey) as? Double {
            lastSyncDate = Date(timeIntervalSince1970: interval)
        }

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
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
            let profilesData = try encoder.encode(persistence.profiles)
            store.set(profilesData, forKey: profilesKey)
            store.set(persistence.hasOnboarded, forKey: onboardedKey)

            for profile in persistence.profiles {
                let chapters = persistence.loadAllChapters(for: profile.id)
                let chaptersData = try encoder.encode(chapters)
                store.set(chaptersData, forKey: chaptersPrefix + profile.id)

                let rewards = persistence.loadRewardState(for: profile.id)
                let rewardsData = try encoder.encode(rewards)
                store.set(rewardsData, forKey: rewardsPrefix + profile.id)

                let readings = persistence.loadAllReadingSessions(for: profile.id)
                let readingsData = try encoder.encode(readings)
                store.set(readingsData, forKey: readingsPrefix + profile.id)
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

    // MARK: - Pull

    func pullFromCloud(persistence: PersistenceService) {
        guard syncEnabled, isICloudAvailable else { return }
        store.synchronize()

        guard let profilesData = store.data(forKey: profilesKey),
              let profiles = try? decoder.decode([ChildProfile].self, from: profilesData),
              !profiles.isEmpty else { return }

        // Only apply if local is empty (new device) or remote is newer
        let remoteTimestamp = store.double(forKey: lastModifiedKey)
        let localTimestamp = defaults.double(forKey: lastSyncKey)

        if persistence.profiles.isEmpty || remoteTimestamp > localTimestamp {
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

        for profile in profiles {
            if let data = store.data(forKey: chaptersPrefix + profile.id),
               let decoded = try? decoder.decode([ChapterProgress].self, from: data) {
                chapters[profile.id] = decoded
            }
            if let data = store.data(forKey: rewardsPrefix + profile.id),
               let decoded = try? decoder.decode(RewardState.self, from: data) {
                rewards[profile.id] = decoded
            }
            if let data = store.data(forKey: readingsPrefix + profile.id),
               let decoded = try? decoder.decode([ReadingSession].self, from: data) {
                readings[profile.id] = decoded
            }
        }

        let hasOnboarded = store.bool(forKey: onboardedKey)

        persistence.applyCloudData(
            profiles: profiles,
            chapters: chapters,
            rewards: rewards,
            readings: readings,
            hasOnboarded: hasOnboarded
        )

        lastSyncDate = Date()
        defaults.set(lastSyncDate!.timeIntervalSince1970, forKey: lastSyncKey)
    }
}
