import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let attributionText = "Exercise data from wger.de, shared under CC-BY-SA licences."
    let attributionURL = URL(string: "https://wger.de")
    let heightRange = UserPreferences.heightRange

    private(set) var errorMessage: String?
    private(set) var isAuthenticating = false

    private let settings: AppSettings
    private let account: AccountSession
    private let deviceAuth: any DeviceAuthenticating

    init(settings: AppSettings, account: AccountSession, deviceAuth: any DeviceAuthenticating) {
        self.settings = settings
        self.account = account
        self.deviceAuth = deviceAuth
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

    var accountSummary: String {
        account.user?.summary ?? "Not signed in"
    }

    var signOutTitle: String {
        account.user?.provider == .google ? "Sign out" : "Leave offline mode"
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func signOut() {
        do {
            try account.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var displayName: String {
        get { settings.preferences.displayName }
        set { settings.update { $0.displayName = newValue } }
    }

    var initial: String {
        let letter = displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()
        return letter.isEmpty ? "W" : letter
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

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    func select(_ gender: GenderPreference) {
        settings.update { $0.gender = gender }
    }

    func select(_ level: FitnessLevel) {
        settings.update { $0.fitnessLevel = level }
    }
}
