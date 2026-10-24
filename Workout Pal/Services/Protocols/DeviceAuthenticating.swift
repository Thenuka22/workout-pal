import Foundation

enum DeviceUnlockKind: Sendable, Equatable {
    case faceID
    case touchID
    case opticID
    case passcode
    case unavailable

    var title: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .passcode: "your passcode"
        case .unavailable: "a passcode"
        }
    }

    var symbolName: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .passcode, .unavailable: "lock.fill"
        }
    }
}

enum DeviceAuthenticationError: Error, LocalizedError, Equatable {
    case cancelled
    case unavailable
    case failed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "Unlock was cancelled."
        case .unavailable:
            "Set a device passcode in Settings to use secure unlock."
        case .failed:
            "Workout Pal couldn't confirm it's you. Try again."
        }
    }
}

protocol DeviceAuthenticating: Sendable {
    func unlockKind() -> DeviceUnlockKind
    func authenticate(reason: String) async throws
}
