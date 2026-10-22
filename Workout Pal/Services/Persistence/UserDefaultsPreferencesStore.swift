import Foundation

struct UserDefaultsPreferencesStore: PreferencesStore, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserPreferences {
        var preferences = UserPreferences.standard
        preferences.displayName = defaults.string(forKey: Keys.displayName) ?? ""
        let goal = defaults.integer(forKey: Keys.weeklyGoal)
        if goal > 0 {
            preferences.weeklyGoal = goal
        }
        if let raw = defaults.string(forKey: Keys.units), let units = UnitPreference(rawValue: raw) {
            preferences.units = units
        }
        if let raw = defaults.string(forKey: Keys.appearance), let appearance = AppearancePreference(rawValue: raw) {
            preferences.appearance = appearance
        }
        if let raw = defaults.string(forKey: Keys.gender) {
            preferences.gender = GenderPreference(rawValue: raw)
        }
        let height = defaults.integer(forKey: Keys.heightCentimetres)
        if UserPreferences.heightRange.contains(height) {
            preferences.heightCentimetres = height
        }
        if let raw = defaults.string(forKey: Keys.fitnessLevel) {
            preferences.fitnessLevel = FitnessLevel(rawValue: raw)
        }
        preferences.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        return preferences
    }

    func save(_ preferences: UserPreferences) {
        defaults.set(preferences.displayName, forKey: Keys.displayName)
        defaults.set(preferences.weeklyGoal, forKey: Keys.weeklyGoal)
        defaults.set(preferences.units.rawValue, forKey: Keys.units)
        defaults.set(preferences.appearance.rawValue, forKey: Keys.appearance)
        defaults.set(preferences.gender?.rawValue, forKey: Keys.gender)
        defaults.set(preferences.heightCentimetres ?? 0, forKey: Keys.heightCentimetres)
        defaults.set(preferences.fitnessLevel?.rawValue, forKey: Keys.fitnessLevel)
        defaults.set(preferences.hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
    }

    private enum Keys {
        static let displayName = "preferences.displayName"
        static let weeklyGoal = "preferences.weeklyGoal"
        static let units = "preferences.units"
        static let appearance = "preferences.appearance"
        static let gender = "preferences.gender"
        static let heightCentimetres = "preferences.heightCentimetres"
        static let fitnessLevel = "preferences.fitnessLevel"
        static let hasCompletedOnboarding = "preferences.hasCompletedOnboarding"
    }
}
