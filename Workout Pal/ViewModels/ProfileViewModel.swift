import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let attributionText = "Exercise data from wger.de, shared under CC-BY-SA licences."
    let attributionURL = URL(string: "https://wger.de")
    let heightRange = UserPreferences.heightRange

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
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
