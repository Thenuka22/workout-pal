import Foundation

struct UserDefaultsPreferencesStore: PreferencesStore, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(ownerID: String) -> UserPreferences {
        let keys = Keys(ownerID: ownerID)
        var preferences = UserPreferences.standard
        preferences.displayName = defaults.string(forKey: keys.displayName) ?? ""
        let goal = defaults.integer(forKey: keys.weeklyGoal)
        if goal > 0 {
            preferences.weeklyGoal = goal
        }
        if let raw = defaults.string(forKey: keys.units), let units = UnitPreference(rawValue: raw) {
            preferences.units = units
        }
        if let raw = defaults.string(forKey: keys.appearance), let appearance = AppearancePreference(rawValue: raw) {
            preferences.appearance = appearance
        }
        if let raw = defaults.string(forKey: keys.gender) {
            preferences.gender = GenderPreference(rawValue: raw)
        }
        let height = defaults.integer(forKey: keys.heightCentimetres)
        if UserPreferences.heightRange.contains(height) {
            preferences.heightCentimetres = height
        }
        if let raw = defaults.string(forKey: keys.fitnessLevel) {
            preferences.fitnessLevel = FitnessLevel(rawValue: raw)
        }
        preferences.hasCompletedOnboarding = defaults.bool(forKey: keys.hasCompletedOnboarding)
        preferences.requiresUnlock = defaults.bool(forKey: keys.requiresUnlock)
        preferences.exportsToHealth = defaults.bool(forKey: keys.exportsToHealth)
        return preferences
    }

    func save(_ preferences: UserPreferences, ownerID: String) {
        let keys = Keys(ownerID: ownerID)
        defaults.set(preferences.displayName, forKey: keys.displayName)
        defaults.set(preferences.weeklyGoal, forKey: keys.weeklyGoal)
        defaults.set(preferences.units.rawValue, forKey: keys.units)
        defaults.set(preferences.appearance.rawValue, forKey: keys.appearance)
        defaults.set(preferences.gender?.rawValue, forKey: keys.gender)
        defaults.set(preferences.heightCentimetres ?? 0, forKey: keys.heightCentimetres)
        defaults.set(preferences.fitnessLevel?.rawValue, forKey: keys.fitnessLevel)
        defaults.set(preferences.hasCompletedOnboarding, forKey: keys.hasCompletedOnboarding)
        defaults.set(preferences.requiresUnlock, forKey: keys.requiresUnlock)
        defaults.set(preferences.exportsToHealth, forKey: keys.exportsToHealth)
    }

    func hasPreferences(ownerID: String) -> Bool {
        defaults.object(forKey: Keys(ownerID: ownerID).hasCompletedOnboarding) != nil
    }

    func removePreferences(ownerID: String) {
        for key in Keys(ownerID: ownerID).all {
            defaults.removeObject(forKey: key)
        }
    }

    private struct Keys {
        let prefix: String

        init(ownerID: String) {
            prefix = ownerID == LocalProfile.ownerID ? "preferences." : "preferences.\(ownerID)."
        }

        var displayName: String { prefix + "displayName" }
        var weeklyGoal: String { prefix + "weeklyGoal" }
        var units: String { prefix + "units" }
        var appearance: String { prefix + "appearance" }
        var gender: String { prefix + "gender" }
        var heightCentimetres: String { prefix + "heightCentimetres" }
        var fitnessLevel: String { prefix + "fitnessLevel" }
        var hasCompletedOnboarding: String { prefix + "hasCompletedOnboarding" }
        var requiresUnlock: String { prefix + "requiresUnlock" }
        var exportsToHealth: String { prefix + "exportsToHealth" }

        var all: [String] {
            [
                displayName, weeklyGoal, units, appearance, gender, heightCentimetres,
                fitnessLevel, hasCompletedOnboarding, requiresUnlock, exportsToHealth,
            ]
        }
    }
}
