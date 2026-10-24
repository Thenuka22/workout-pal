import AVFoundation
import CoreMotion
import Foundation
import HealthKit
import LocalAuthentication
import UserNotifications

@MainActor
final class SystemPermissions: PermissionsProviding {
    private let healthStore = HKHealthStore()

    func status(of permission: AppPermission) async -> PermissionStatus {
        switch permission {
        case .camera:
            return cameraStatus()
        case .motion:
            return motionStatus()
        case .health:
            return await healthStatus()
        case .notifications:
            return await notificationStatus()
        case .deviceUnlock:
            return deviceUnlockStatus()
        }
    }

    func request(_ permission: AppPermission) async -> PermissionStatus {
        switch permission {
        case .camera:
            if cameraStatus() == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
            return cameraStatus()
        case .motion:
            if motionStatus() == .notDetermined {
                await queryRecentSteps()
            }
            return motionStatus()
        case .health:
            guard HKHealthStore.isHealthDataAvailable() else {
                return .unavailable
            }
            await requestHealthAccess()
            return await healthStatus()
        case .notifications:
            await requestNotifications()
            return await notificationStatus()
        case .deviceUnlock:
            return deviceUnlockStatus()
        }
    }

    private func cameraStatus() -> PermissionStatus {
        guard AVCaptureDevice.default(for: .video) != nil else {
            return .unavailable
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unavailable
        }
    }

    private func motionStatus() -> PermissionStatus {
        guard CMPedometer.isStepCountingAvailable() || CMMotionActivityManager.isActivityAvailable() else {
            return .unavailable
        }
        switch CMPedometer.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unavailable
        }
    }

    private func queryRecentSteps() async {
        let pedometer = CMPedometer()
        let end = Date.now
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pedometer.queryPedometerData(from: end.addingTimeInterval(-3_600), to: end) { @Sendable _, _ in
                continuation.resume()
            }
        }
        withExtendedLifetime(pedometer) {}
    }

    private func healthStatus() async -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }
        let store = healthStore
        return await withCheckedContinuation { (continuation: CheckedContinuation<PermissionStatus, Never>) in
            store.getRequestStatusForAuthorization(
                toShare: HealthDataTypes.share,
                read: HealthDataTypes.read
            ) { @Sendable status, error in
                guard error == nil else {
                    continuation.resume(returning: .unavailable)
                    return
                }
                continuation.resume(returning: status == .unnecessary ? .granted : .notDetermined)
            }
        }
    }

    private func requestHealthAccess() async {
        let store = healthStore
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.requestAuthorization(toShare: HealthDataTypes.share, read: HealthDataTypes.read) { @Sendable _, _ in
                continuation.resume()
            }
        }
    }

    private func notificationStatus() async -> PermissionStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<PermissionStatus, Never>) in
            UNUserNotificationCenter.current().getNotificationSettings { @Sendable settings in
                continuation.resume(returning: Self.permissionStatus(settings.authorizationStatus))
            }
        }
    }

    private func requestNotifications() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { @Sendable _, _ in
                continuation.resume()
            }
        }
    }

    private func deviceUnlockStatus() -> PermissionStatus {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) ? .granted : .unavailable
    }

    nonisolated private static func permissionStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .granted
        @unknown default: .unavailable
        }
    }
}
