import Foundation
import Testing
@testable import Workout_Pal

struct PreferencesStoreTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "WorkoutPalTests.\(UUID().uuidString)"))
    }

    @Test func emptyStoreReturnsTheDefaults() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        #expect(store.load() == .standard)
    }

    @Test func savedPreferencesComeBack() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        var preferences = UserPreferences.standard
        preferences.displayName = "Induwara"
        preferences.weeklyGoal = 4
        preferences.units = .pounds
        preferences.appearance = .system
        preferences.gender = .female
        preferences.heightCentimetres = 162
        preferences.fitnessLevel = .intermediate
        preferences.hasCompletedOnboarding = true
        store.save(preferences)
        #expect(store.load() == preferences)
    }

    @Test func outOfRangeHeightIsIgnored() throws {
        let defaults = try makeDefaults()
        defaults.set(400, forKey: "preferences.heightCentimetres")
        #expect(UserDefaultsPreferencesStore(defaults: defaults).load().heightCentimetres == nil)
    }
}
