@MainActor
protocol PermissionsProviding: AnyObject {
    func status(of permission: AppPermission) async -> PermissionStatus
    func request(_ permission: AppPermission) async -> PermissionStatus
}
