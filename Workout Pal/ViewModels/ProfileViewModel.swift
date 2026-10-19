import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let attributionText = "Exercise data from wger.de, shared under CC-BY-SA licences."
    let attributionURL = URL(string: "https://wger.de")

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    var displayName: String {
        get { settings.preferences.displayName }
        set { settings.update { $0.displayName = newValue } }
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

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
