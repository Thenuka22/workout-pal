import Testing
@testable import Workout_Pal

@MainActor
struct PermissionsViewModelTests {
    private let permissions = FakePermissions()

    private func row(_ permission: AppPermission, in model: PermissionsViewModel) -> PermissionRow? {
        model.rows.first { $0.permission == permission }
    }

    @Test func loadShowsEveryPermission() async {
        permissions.statuses = [.camera: .granted, .motion: .denied, .health: .unavailable]
        let model = PermissionsViewModel(permissions: permissions)
        await model.load()
        #expect(model.rows.count == AppPermission.allCases.count)
        #expect(row(.camera, in: model)?.statusText == "Allowed")
        #expect(row(.motion, in: model)?.needsSettings == true)
        #expect(row(.health, in: model)?.statusText == "Not available on this device")
        #expect(row(.notifications, in: model)?.canRequest == true)
        #expect(!model.isLoading)
    }

    @Test func requestingUpdatesOnlyThatRow() async {
        let model = PermissionsViewModel(permissions: permissions)
        await model.load()
        model.request(.camera)
        #expect(await eventually { self.row(.camera, in: model)?.status == .granted })
        #expect(permissions.requested == [.camera])
        #expect(row(.motion, in: model)?.status == .notDetermined)
    }

    @Test func healthShowsConnectedRatherThanAllowed() {
        #expect(AppPermission.health.statusText(.granted) == "Access requested")
        #expect(AppPermission.deviceUnlock.statusText(.unavailable) == "Set a passcode first")
    }
}
