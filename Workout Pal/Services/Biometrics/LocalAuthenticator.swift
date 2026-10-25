import Foundation
import LocalAuthentication

struct LocalAuthenticator: DeviceAuthenticating {
    func unlockKind() -> DeviceUnlockKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .passcode
        }
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var availability: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availability) else {
            throw DeviceAuthenticationError.unavailable
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { @Sendable success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: Self.mapped(error))
                }
            }
        }
        Self.keepAlive(context)
    }

    private static func keepAlive(_ object: AnyObject) {
        withExtendedLifetime(object) {}
    }

    private static func mapped(_ error: Error?) -> DeviceAuthenticationError {
        guard let error = error as? LAError else {
            return .failed
        }
        switch error.code {
        case .userCancel, .appCancel, .systemCancel:
            return .cancelled
        case .passcodeNotSet:
            return .unavailable
        default:
            return .failed
        }
    }
}
