import Foundation
import Observation

@MainActor
@Observable
final class HealthSettingsViewModel {
    let notes = [
        "Workout Pal reads your steps, walking and running distance and workouts.",
        "Finished workouts, walks and runs are saved with their type and active time. Sets and reps stay in Workout Pal.",
        "Steps your iPhone already records aren't saved again, so they are never counted twice.",
        "Deleting a workout in Workout Pal doesn't delete the copy in Apple Health. Remove it in the Health app if you need to.",
    ]

    private(set) var access: PermissionStatus = .notDetermined
    private(set) var isLoading = true

    private let settings: AppSettings
    private let permissions: any PermissionsProviding
    private let health: any HealthService

    init(settings: AppSettings, permissions: any PermissionsProviding, health: any HealthService) {
        self.settings = settings
        self.permissions = permissions
        self.health = health
    }

    var isAvailable: Bool {
        health.isAvailable
    }

    var isConnected: Bool {
        access == .granted
    }

    var statusText: String {
        isAvailable ? AppPermission.health.statusText(access) : AppPermission.health.statusText(.unavailable)
    }

    var exportsToHealth: Bool {
        settings.preferences.exportsToHealth
    }

    func load() async {
        access = await permissions.status(of: .health)
        isLoading = false
    }

    func connect() {
        Task {
            self.access = await self.permissions.request(.health)
        }
    }

    func setExportsToHealth(_ enabled: Bool) {
        settings.update { $0.exportsToHealth = enabled }
        if enabled && !isConnected {
            connect()
        }
    }
}
