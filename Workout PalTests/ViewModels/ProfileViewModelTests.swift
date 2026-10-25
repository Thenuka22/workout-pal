import Testing
@testable import Workout_Pal

@MainActor
struct ProfileViewModelTests {
    private let permissions = FakePermissions()
    private let deviceAuth = FakeDeviceAuth()
    private let records = RecordingAccountDataRepository()
    private let settings = AppSettings(store: InMemoryPreferencesStore())

    private func makeModel() -> ProfileViewModel {
        let account = AccountSession(
            auth: FakeAuthService(),
            records: records,
            settings: settings,
            state: FakeAccountStateStore(),
            notifications: FakeNotifications()
        )
        account.continueOffline()
        return ProfileViewModel(settings: settings, account: account, deviceAuth: deviceAuth, permissions: permissions)
    }

    private func service(_ id: String, in model: ProfileViewModel) -> ConnectedService? {
        model.connectedServices.first { $0.id == id }
    }

    @Test func connectedServicesShowLiveStatuses() async {
        permissions.statuses = [.health: .granted, .motion: .denied, .camera: .granted]
        let model = makeModel()
        await model.load()
        #expect(service("health", in: model)?.value == "Connected")
        #expect(service("motion", in: model)?.value == "Turned off")
        #expect(service("camera", in: model)?.value == "Ready")
        #expect(service("reminders", in: model)?.value == "Off")
        #expect(service("health", in: model)?.route == .health)
    }

    @Test func turningOnSecureUnlockNeedsFaceID() async {
        let model = makeModel()
        model.setRequiresUnlock(true)
        #expect(await eventually { model.requiresUnlock })
        #expect(deviceAuth.attempts == 1)
        model.setRequiresUnlock(false)
        #expect(!model.requiresUnlock)
        #expect(deviceAuth.attempts == 1)
    }

    @Test func cancelledFaceIDLeavesTheLockOff() async {
        deviceAuth.failure = .cancelled
        let model = makeModel()
        model.setRequiresUnlock(true)
        #expect(await eventually { !model.isAuthenticating && deviceAuth.attempts == 1 })
        #expect(!model.requiresUnlock)
        #expect(model.errorMessage == nil)
    }

    @Test func deletingDataClearsTheOfflineProfile() async {
        settings.update { $0.hasCompletedOnboarding = true }
        let model = makeModel()
        model.deleteWorkoutData()
        #expect(await eventually { !model.isDeletingData && !settings.preferences.hasCompletedOnboarding })
        #expect(await records.deleted == [LocalProfile.ownerID])
    }

    @Test func offlineModeOffersToLeaveIt() {
        let model = makeModel()
        #expect(model.signOutTitle == "Leave offline mode")
        #expect(model.profileSubtitle == "Your training profile")
    }
}
