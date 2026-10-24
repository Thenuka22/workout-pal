@testable import Workout_Pal

final class FakeDeviceAuth: DeviceAuthenticating, @unchecked Sendable {
    var kind: DeviceUnlockKind = .faceID
    var failure: DeviceAuthenticationError?
    private(set) var attempts = 0

    func unlockKind() -> DeviceUnlockKind {
        kind
    }

    func authenticate(reason: String) async throws {
        attempts += 1
        if let failure {
            throw failure
        }
    }
}

struct ReadyStore: PersistentStore {
    func load() async throws {}
}
