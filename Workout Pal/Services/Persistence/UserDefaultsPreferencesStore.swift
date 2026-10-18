import Foundation

struct UserDefaultsPreferencesStore: PreferencesStore {
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
        return preferences
    }

    func save(_ preferences: UserPreferences) {
        defaults.set(preferences.displayName, forKey: Keys.displayName)
        defaults.set(preferences.weeklyGoal, forKey: Keys.weeklyGoal)
        defaults.set(preferences.units.rawValue, forKey: Keys.units)
        defaults.set(preferences.appearance.rawValue, forKey: Keys.appearance)
    }

    private enum Keys {
        static let displayName = "preferences.displayName"
        static let weeklyGoal = "preferences.weeklyGoal"
        static let units = "preferences.units"
        static let appearance = "preferences.appearance"
    }
}
