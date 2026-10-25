import Foundation
import Testing
@testable import Workout_Pal

struct PreferencesStoreTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "WorkoutPalTests.\(UUID().uuidString)"))
    }

    private var sample: UserPreferences {
        var preferences = UserPreferences.standard
        preferences.displayName = "Induwara"
        preferences.weeklyGoal = 4
        preferences.units = .pounds
        preferences.appearance = .system
        preferences.gender = .female
        preferences.heightCentimetres = 162
        preferences.fitnessLevel = .intermediate
        preferences.hasCompletedOnboarding = true
        return preferences
    }

    @Test func emptyStoreReturnsTheDefaults() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        #expect(store.load(ownerID: LocalProfile.ownerID) == .standard)
        #expect(!store.hasPreferences(ownerID: LocalProfile.ownerID))
    }

    @Test func savedPreferencesComeBack() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        store.save(sample, ownerID: "google-uid")
        #expect(store.load(ownerID: "google-uid") == sample)
        #expect(store.hasPreferences(ownerID: "google-uid"))
    }

    @Test func eachAccountHasItsOwnPreferences() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        store.save(sample, ownerID: "account-a")
        #expect(store.load(ownerID: "account-b") == .standard)
        #expect(store.load(ownerID: LocalProfile.ownerID) == .standard)
    }

    @Test func localProfileKeepsTheOriginalKeys() throws {
        let defaults = try makeDefaults()
        defaults.set("Kept", forKey: "preferences.displayName")
        defaults.set(true, forKey: "preferences.hasCompletedOnboarding")
        let store = UserDefaultsPreferencesStore(defaults: defaults)
        #expect(store.load(ownerID: LocalProfile.ownerID).displayName == "Kept")
        #expect(store.load(ownerID: LocalProfile.ownerID).hasCompletedOnboarding)
    }

    @Test func removingPreferencesResetsTheAccount() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        store.save(sample, ownerID: "google-uid")
        store.removePreferences(ownerID: "google-uid")
        #expect(store.load(ownerID: "google-uid") == .standard)
        #expect(!store.hasPreferences(ownerID: "google-uid"))
    }

    @Test func outOfRangeHeightIsIgnored() throws {
        let defaults = try makeDefaults()
        defaults.set(400, forKey: "preferences.heightCentimetres")
        #expect(UserDefaultsPreferencesStore(defaults: defaults).load(ownerID: LocalProfile.ownerID).heightCentimetres == nil)
    }

    @Test func feedbackSettingsDefaultToOn() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        let preferences = store.load(ownerID: LocalProfile.ownerID)
        #expect(preferences.spokenRepCount)
        #expect(preferences.hapticsEnabled)
        #expect(preferences.restAlertsEnabled)
    }

    @Test func turnedOffFeedbackIsRemembered() throws {
        let store = UserDefaultsPreferencesStore(defaults: try makeDefaults())
        var preferences = UserPreferences.standard
        preferences.spokenRepCount = false
        preferences.hapticsEnabled = false
        store.save(preferences, ownerID: "uid")
        let loaded = store.load(ownerID: "uid")
        #expect(!loaded.spokenRepCount)
        #expect(!loaded.hapticsEnabled)
    }
}
