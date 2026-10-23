@testable import Workout_Pal

@MainActor
final class FakePermissions: PermissionsProviding {
    var statuses: [AppPermission: PermissionStatus] = [:]
    var statusAfterRequest: PermissionStatus = .granted
    private(set) var requested: [AppPermission] = []

    func status(of permission: AppPermission) async -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    func request(_ permission: AppPermission) async -> PermissionStatus {
        requested.append(permission)
        statuses[permission] = statusAfterRequest
        return statusAfterRequest
    }
}
