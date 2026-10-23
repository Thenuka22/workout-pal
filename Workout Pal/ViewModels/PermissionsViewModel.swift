import Foundation
import Observation

struct PermissionRow: Identifiable, Hashable {
    let permission: AppPermission
    var status: PermissionStatus

    var id: AppPermission { permission }

    var statusText: String {
        permission.statusText(status)
    }

    var canRequest: Bool {
        status == .notDetermined
    }

    var needsSettings: Bool {
        status == .denied
    }
}

@MainActor
@Observable
final class PermissionsViewModel {
    let privacyNotes = [
        "Camera frames are analysed on this device and never saved or uploaded.",
        "Your workouts are stored in Workout Pal on this device.",
        "Apple Health does not tell apps whether reading is allowed. Choose what Workout Pal can read in the Health app.",
    ]

    private(set) var rows: [PermissionRow] = AppPermission.allCases.map {
        PermissionRow(permission: $0, status: .notDetermined)
    }
    private(set) var isLoading = true

    private let permissions: any PermissionsProviding

    init(permissions: any PermissionsProviding) {
        self.permissions = permissions
    }

    func load() async {
        var updated = rows
        for index in updated.indices {
            updated[index].status = await permissions.status(of: updated[index].permission)
        }
        rows = updated
        isLoading = false
    }

    func refresh() {
        Task {
            await self.load()
        }
    }

    func request(_ permission: AppPermission) {
        Task {
            let status = await self.permissions.request(permission)
            if let index = self.rows.firstIndex(where: { $0.permission == permission }) {
                self.rows[index].status = status
            }
        }
    }
}
