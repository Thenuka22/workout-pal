import Testing
@testable import Workout_Pal

@MainActor
struct RootViewModelTests {
    private let deviceAuth = FakeDeviceAuth()
    private let auth = FakeAuthService()
    private let state = FakeAccountStateStore()

    private func makeModel(requiresUnlock: Bool = true, onboarded: Bool = true) -> RootViewModel {
        var preferences = UserPreferences.standard
        preferences.hasCompletedOnboarding = onboarded
        preferences.requiresUnlock = requiresUnlock
        let settings = AppSettings(store: InMemoryPreferencesStore(preferences))
        state.usesOfflineProfile = true
        let account = AccountSession(
            auth: auth,
            records: RecordingAccountDataRepository(),
            settings: settings,
            state: state,
            notifications: FakeNotifications()
        )
        return RootViewModel(store: ReadyStore(), settings: settings, account: account, deviceAuth: deviceAuth)
    }

    @Test func signedOutVisitorsSeeTheWelcomeScreen() async {
        state.usesOfflineProfile = false
        let settings = AppSettings(store: InMemoryPreferencesStore())
        let account = AccountSession(
            auth: auth,
            records: RecordingAccountDataRepository(),
            settings: settings,
            state: state,
            notifications: FakeNotifications()
        )
        let model = RootViewModel(store: ReadyStore(), settings: settings, account: account, deviceAuth: deviceAuth)
        await model.loadStore()
        #expect(model.screen == .welcome)
    }

    @Test func unfinishedProfileGoesToOnboarding() async {
        let model = makeModel(requiresUnlock: false, onboarded: false)
        await model.loadStore()
        #expect(model.screen == .onboarding)
    }

    @Test func secureUnlockAsksAtLaunch() async {
        let model = makeModel()
        await model.loadStore()
        #expect(model.screen == .main)
        #expect(await eventually { !model.isLocked })
        #expect(deviceAuth.attempts == 1)
    }

    @Test func cancellingKeepsTheAppLocked() async {
        deviceAuth.failure = .cancelled
        let model = makeModel()
        await model.loadStore()
        #expect(await eventually { deviceAuth.attempts == 1 && !model.isUnlocking })
        #expect(model.showsLock)
        #expect(model.unlockMessage == nil)
    }

    @Test func failedUnlockExplainsWhy() async {
        deviceAuth.failure = .failed
        let model = makeModel()
        await model.loadStore()
        #expect(await eventually { model.unlockMessage != nil })
        #expect(model.showsLock)
    }

    @Test func leavingTheAppLocksItAgainAndAsksOnce() async {
        let model = makeModel()
        await model.loadStore()
        #expect(await eventually { !model.isLocked })
        model.sceneDidEnterBackground()
        #expect(model.showsLock)
        model.sceneDidBecomeActive()
        #expect(await eventually { !model.isLocked })
        model.sceneDidBecomeActive()
        #expect(deviceAuth.attempts == 2)
    }

    @Test func noLockWhenSecureUnlockIsOff() async {
        let model = makeModel(requiresUnlock: false)
        await model.loadStore()
        model.sceneDidEnterBackground()
        #expect(!model.showsLock)
        #expect(deviceAuth.attempts == 0)
    }

    private func makeSignedOutModel(store: InMemoryPreferencesStore, claimed: Bool = true) -> (RootViewModel, AccountSession) {
        state.usesOfflineProfile = false
        state.hasClaimedLocalData = claimed
        let settings = AppSettings(store: store)
        let account = AccountSession(
            auth: auth,
            records: RecordingAccountDataRepository(),
            settings: settings,
            state: state,
            notifications: FakeNotifications()
        )
        return (RootViewModel(store: ReadyStore(), settings: settings, account: account, deviceAuth: deviceAuth), account)
    }

    @Test func signingInToALockedAccountAsksToUnlock() async throws {
        var mine = UserPreferences.standard
        mine.hasCompletedOnboarding = true
        mine.requiresUnlock = true
        let (model, account) = makeSignedOutModel(store: InMemoryPreferencesStore(mine, ownerID: "google-uid"))
        await model.loadStore()
        #expect(model.screen == .welcome)
        deviceAuth.failure = .cancelled
        try await account.signInWithGoogle()
        model.accountDidActivate()
        #expect(model.screen == .main)
        #expect(model.showsLock)
        #expect(await eventually { deviceAuth.attempts == 1 && !model.isUnlocking })
        #expect(model.showsLock)
    }

    @Test func newAccountsAreNotLockedWhileSettingUp() async throws {
        var local = UserPreferences.standard
        local.hasCompletedOnboarding = true
        local.requiresUnlock = true
        let (model, account) = makeSignedOutModel(store: InMemoryPreferencesStore(local), claimed: false)
        await model.loadStore()
        try await account.signInWithGoogle()
        model.accountDidActivate()
        #expect(model.screen == .onboarding)
        #expect(!model.isLocked)
        model.sceneDidEnterBackground()
        #expect(!model.isLocked)
        #expect(deviceAuth.attempts == 0)
    }

    @Test func signingOutFromTheLockScreenReturnsToWelcome() async {
        deviceAuth.failure = .cancelled
        let model = makeModel()
        await model.loadStore()
        model.signOutFromLock()
        #expect(model.screen == .welcome)
        #expect(!model.showsLock)
    }
}
