import Foundation

@Observable
@MainActor
class CloudSyncService {
    private let deviceIdKey = "geni_device_sync_id"
    private let syncCodeKey = "geni_sync_code"
    private let lastSyncKey = "geni_last_sync"
    private let defaults = UserDefaults.standard

    var syncCode: String = ""
    var lastSyncDate: Date? = nil
    var isSyncing: Bool = false
    var syncError: String? = nil

    var deviceId: String {
        if let existing = defaults.string(forKey: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        defaults.set(newId, forKey: deviceIdKey)
        return newId
    }

    init() {
        syncCode = defaults.string(forKey: syncCodeKey) ?? generateSyncCode()
        if let interval = defaults.object(forKey: lastSyncKey) as? Double {
            lastSyncDate = Date(timeIntervalSince1970: interval)
        }
    }

    private func generateSyncCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let code = String((0..<6).map { _ in chars.randomElement()! })
        defaults.set(code, forKey: syncCodeKey)
        return code
    }

    func syncToCloud(persistence: PersistenceService) {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil

        Task {
            do {
                let payload = buildSyncPayload(persistence: persistence)
                try await uploadPayload(payload)
                lastSyncDate = Date()
                defaults.set(lastSyncDate!.timeIntervalSince1970, forKey: lastSyncKey)
                isSyncing = false
            } catch {
                syncError = error.localizedDescription
                isSyncing = false
            }
        }
    }

    func restoreFromCloud(code: String, persistence: PersistenceService) async -> Bool {
        isSyncing = true
        syncError = nil

        do {
            guard let payload = try await downloadPayload(code: code) else {
                syncError = "No data found for this code"
                isSyncing = false
                return false
            }
            applySyncPayload(payload, persistence: persistence)
            syncCode = code
            defaults.set(code, forKey: syncCodeKey)
            isSyncing = false
            return true
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
            return false
        }
    }

    private func buildSyncPayload(persistence: PersistenceService) -> SyncPayload {
        var allChapters: [String: [ChapterProgress]] = [:]
        var allRewards: [String: RewardState] = [:]

        for profile in persistence.profiles {
            allChapters[profile.id] = persistence.loadAllChapters(for: profile.id)
            allRewards[profile.id] = persistence.loadRewardState(for: profile.id)
        }

        return SyncPayload(
            deviceId: deviceId,
            syncCode: syncCode,
            profiles: persistence.profiles,
            chapters: allChapters,
            rewards: allRewards,
            parentPin: persistence.parentPin,
            hasOnboarded: persistence.hasOnboarded,
            timestamp: Date()
        )
    }

    private func applySyncPayload(_ payload: SyncPayload, persistence: PersistenceService) {
        for profile in payload.profiles {
            persistence.saveProfile(profile)
        }

        for (childId, chapters) in payload.chapters {
            for chapter in chapters {
                persistence.saveChapterProgress(chapter)
            }
            if let rewards = payload.rewards[childId] {
                persistence.saveRewardState(rewards, for: childId)
            }
        }

        if let pin = payload.parentPin {
            persistence.setPin(pin)
        }

        if payload.hasOnboarded {
            persistence.completeOnboarding()
        }
    }

    private func uploadPayload(_ payload: SyncPayload) async throws {
        let baseURL = Config.EXPO_PUBLIC_RORK_API_BASE_URL
        guard !baseURL.isEmpty else { return }

        let url = URL(string: "\(baseURL)/sync/\(payload.syncCode)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return
        }
    }

    private func downloadPayload(code: String) async throws -> SyncPayload? {
        let baseURL = Config.EXPO_PUBLIC_RORK_API_BASE_URL
        guard !baseURL.isEmpty else { return nil }

        let url = URL(string: "\(baseURL)/sync/\(code)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SyncPayload.self, from: data)
    }
}

nonisolated struct SyncPayload: Codable, Sendable {
    let deviceId: String
    let syncCode: String
    let profiles: [ChildProfile]
    let chapters: [String: [ChapterProgress]]
    let rewards: [String: RewardState]
    let parentPin: String?
    let hasOnboarded: Bool
    let timestamp: Date
}
