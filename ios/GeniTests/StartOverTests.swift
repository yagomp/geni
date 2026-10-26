import Foundation
import Testing
@testable import Geni

/// "Start over" in the parent area: back to welcome here and on every synced device.
@MainActor
struct StartOverTests {
    private func relaunch(_ device: TestDevice, cloud: InMemoryCloudStore) -> AppViewModel {
        AppViewModel(
            persistence: PersistenceService(defaults: device.defaults),
            cloudSync: CloudSyncService(store: cloud, defaults: device.defaults, isICloudAvailable: { true })
        )
    }

    @Test func startOverReturnsToWelcomeEverywhereAndStaysThere() {
        let cloud = InMemoryCloudStore()
        let phone = TestDevice(cloudStore: cloud)
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let b = ChildProfile(nickname: "B", age: 4, avatarId: "lion")
        let vm = phone.makeViewModel()
        vm.completeOnboarding(profile: a)
        vm.saveProfile(b)
        var rewards = RewardState()
        rewards.coins = 50
        phone.persistence.saveRewardState(rewards, for: a.id)
        phone.cloud.pushToCloud(persistence: phone.persistence)

        let tablet = TestDevice(cloudStore: cloud)
        let tabletVM = tablet.makeViewModel()
        #expect(tablet.persistence.profiles.count == 2)

        vm.resetApp()

        #expect(vm.currentScreen == .welcome)
        #expect(!vm.showParentSettings)
        #expect(vm.rewardState.coins == 0)
        #expect(phone.persistence.profiles.isEmpty)
        #expect(!phone.persistence.hasOnboarded)
        #expect(phone.persistence.activeProfileId == nil)
        #expect(phone.persistence.loadRewardState(for: a.id).coins == 0)

        // iCloud must not bring the children back on the next launch
        let relaunched = relaunch(phone, cloud: cloud)
        #expect(relaunched.currentScreen == .welcome)
        #expect(relaunched.persistence.profiles.isEmpty)

        // The other device drops them when iCloud reports the change
        tabletVM.applyExternalCloudChange()
        #expect(tablet.persistence.profiles.isEmpty)
        #expect(tabletVM.currentScreen == .welcome)

        // A new child after starting over syncs normally
        let c = ChildProfile(nickname: "C", age: 5, avatarId: "lion")
        relaunched.completeOnboarding(profile: c)
        relaunched.cloudSync.pushToCloud(persistence: relaunched.persistence)
        tabletVM.applyExternalCloudChange()
        #expect(tablet.persistence.profiles.map(\.id) == [c.id])
    }

    @Test func staleDeviceCannotBringChildrenBack() {
        let cloud = InMemoryCloudStore()
        let phone = TestDevice(cloudStore: cloud)
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let vm = phone.makeViewModel()
        vm.completeOnboarding(profile: a)
        phone.cloud.pushToCloud(persistence: phone.persistence)

        let tablet = TestDevice(cloudStore: cloud)
        let tabletVM = tablet.makeViewModel()
        #expect(tablet.persistence.profiles.map(\.id) == [a.id])
        // Snapshot of iCloud as the tablet last saw it, before the reset reaches it
        let stale = cloud.values

        vm.resetApp()
        // The tablet writes its old view back (last writer wins per key)
        for (key, value) in stale { cloud.values[key] = value }

        // The phone hears about that write and re-asserts its deletions
        vm.applyExternalCloudChange()
        #expect(phone.persistence.profiles.isEmpty)
        #expect(!phone.persistence.hasOnboarded)
        #expect(vm.currentScreen == .welcome)

        tabletVM.applyExternalCloudChange()
        #expect(tablet.persistence.profiles.isEmpty)
        #expect(!tablet.persistence.hasOnboarded)
        #expect(tabletVM.currentScreen == .welcome)

        let fresh = relaunch(phone, cloud: cloud)
        #expect(fresh.currentScreen == .welcome && fresh.persistence.profiles.isEmpty)
    }

    @Test func childOnlyInICloudIsAlsoRemoved() {
        let cloud = InMemoryCloudStore()
        let phone = TestDevice(cloudStore: cloud)
        let a = ChildProfile(nickname: "A", age: 7, avatarId: "lion")
        let vm = phone.makeViewModel()
        vm.completeOnboarding(profile: a)
        phone.cloud.pushToCloud(persistence: phone.persistence)

        // The tablet adds X; the phone hasn't pulled it
        let tablet = TestDevice(cloudStore: cloud)
        let tabletVM = tablet.makeViewModel()
        let x = ChildProfile(nickname: "X", age: 5, avatarId: "lion")
        tabletVM.saveProfile(x)
        tablet.cloud.pushToCloud(persistence: tablet.persistence)

        vm.resetApp()
        #expect(phone.persistence.deletedProfileIds.isSuperset(of: [a.id, x.id]))

        tabletVM.applyExternalCloudChange()
        #expect(tablet.persistence.profiles.isEmpty)
        #expect(relaunch(phone, cloud: cloud).persistence.profiles.isEmpty)
    }

    @Test func parentInOnboardingIsNotSentBackToWelcome() {
        let cloud = InMemoryCloudStore()
        let phone = TestDevice(cloudStore: cloud)
        let vm = phone.makeViewModel()
        vm.currentScreen = .onboarding
        vm.applyExternalCloudChange()
        #expect(vm.currentScreen == .onboarding)
    }
}
