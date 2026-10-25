import Foundation
import Observation

struct ConnectedService: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let value: String
    let isActive: Bool
    let route: ProfileRoute
}

@MainActor
@Observable
final class ProfileViewModel {
    let attributionText = "Exercise data from wger.de, shared under CC-BY-SA licences."
    let attributionURL = URL(string: "https://wger.de")
    let heightRange = UserPreferences.heightRange

    private(set) var errorMessage: String?
    private(set) var isAuthenticating = false
    private(set) var isDeletingData = false
    private(set) var statuses: [AppPermission: PermissionStatus] = [:]

    private let settings: AppSettings
    private let account: AccountSession
    private let deviceAuth: any DeviceAuthenticating
    private let permissions: any PermissionsProviding

    init(
        settings: AppSettings,
        account: AccountSession,
        deviceAuth: any DeviceAuthenticating,
        permissions: any PermissionsProviding
    ) {
        self.settings = settings
        self.account = account
        self.deviceAuth = deviceAuth
        self.permissions = permissions
    }

    var displayName: String {
        get { settings.preferences.displayName }
        set { settings.update { $0.displayName = newValue } }
    }

    var initial: String {
        let letter = displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()
        return letter.isEmpty ? "W" : letter
    }

    var profileSubtitle: String {
        if let email = account.user?.email, !email.isEmpty {
            return email
        }
        return "Your training profile"
    }

    var weeklyGoal: Int {
        get { settings.preferences.weeklyGoal }
        set { settings.update { $0.weeklyGoal = newValue } }
    }

    var units: UnitPreference {
        get { settings.preferences.units }
        set { settings.update { $0.units = newValue } }
    }

    var appearance: AppearancePreference {
        get { settings.preferences.appearance }
        set { settings.update { $0.appearance = newValue } }
    }

    var gender: GenderPreference? {
        settings.preferences.gender
    }

    var fitnessLevel: FitnessLevel? {
        settings.preferences.fitnessLevel
    }

    var heightCentimetres: Int {
        get { settings.preferences.heightCentimetres ?? 170 }
        set { settings.update { $0.heightCentimetres = newValue } }
    }

    var heightText: String {
        if let height = settings.preferences.heightCentimetres {
            return "\(height) cm"
        }
        return "Not set"
    }

    var planSummary: String {
        guard let fitnessLevel else {
            return "Tell us your level and we'll suggest a weekly goal."
        }
        return "\(fitnessLevel.title) · suggested \(fitnessLevel.suggestedWeeklyGoal) workouts a week"
    }

    var reminderSummary: String {
        Formatting.reminder(settings.preferences)
    }

    var connectedServices: [ConnectedService] {
        let health = status(of: .health)
        let motion = status(of: .motion)
        let camera = status(of: .camera)
        let remindersOn = reminderSummary != "Off"
        return [
            ConnectedService(
                id: "health",
                title: "Apple Health",
                subtitle: settings.preferences.exportsToHealth ? "Read and save workout activity" : "Read workout activity",
                symbolName: "heart.fill",
                value: AppPermission.health.statusText(health),
                isActive: health == .granted,
                route: .health
            ),
            ConnectedService(
                id: "motion",
                title: "Movement tracking",
                subtitle: "Walking and running activity",
                symbolName: "figure.walk.motion",
                value: motion == .granted ? "Enabled" : AppPermission.motion.statusText(motion),
                isActive: motion == .granted,
                route: .permissions
            ),
            ConnectedService(
                id: "reminders",
                title: "Workout reminders",
                subtitle: reminderSummary,
                symbolName: "bell.fill",
                value: remindersOn ? "On" : "Off",
                isActive: remindersOn,
                route: .reminders
            ),
            ConnectedService(
                id: "camera",
                title: "Camera rep counting",
                subtitle: "Vision pose detection",
                symbolName: "camera.viewfinder",
                value: camera == .granted ? "Ready" : AppPermission.camera.statusText(camera),
                isActive: camera == .granted,
                route: .permissions
            ),
        ]
    }

    var unlockKind: DeviceUnlockKind {
        deviceAuth.unlockKind()
    }

    var requiresUnlock: Bool {
        settings.preferences.requiresUnlock
    }

    var secureUnlockTitle: String {
        "Lock with \(unlockKind.title)"
    }

    var secureUnlockDetail: String {
        if unlockKind == .unavailable {
            return "Set a device passcode in Settings to lock Workout Pal."
        }
        return "Ask for \(unlockKind.title) when you come back to Workout Pal. Your passcode works too."
    }

    var accountSummary: String {
        account.user?.summary ?? "Not signed in"
    }

    var signOutTitle: String {
        account.user?.provider == .google ? "Sign out" : "Leave offline mode"
    }

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func load() async {
        var updated: [AppPermission: PermissionStatus] = [:]
        for permission in [AppPermission.health, .motion, .camera] {
            updated[permission] = await permissions.status(of: permission)
        }
        statuses = updated
    }

    func select(_ gender: GenderPreference) {
        settings.update { $0.gender = gender }
    }

    func select(_ level: FitnessLevel) {
        settings.update { $0.fitnessLevel = level }
    }

    func setRequiresUnlock(_ enabled: Bool) {
        guard enabled else {
            settings.update { $0.requiresUnlock = false }
            return
        }
        guard !isAuthenticating else {
            return
        }
        isAuthenticating = true
        Task {
            do {
                try await self.deviceAuth.authenticate(reason: "Turn on secure unlock for Workout Pal")
                self.settings.update { $0.requiresUnlock = true }
            } catch DeviceAuthenticationError.cancelled {
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isAuthenticating = false
        }
    }

    func signOut() {
        do {
            try account.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWorkoutData() {
        guard !isDeletingData else {
            return
        }
        isDeletingData = true
        Task {
            do {
                try await self.account.deleteLocalData()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isDeletingData = false
        }
    }

    private func status(of permission: AppPermission) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }
}
