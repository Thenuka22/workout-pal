import Foundation
@testable import Workout_Pal

final class InMemoryPreferencesStore: PreferencesStore, @unchecked Sendable {
    private var preferences: UserPreferences

    init(_ preferences: UserPreferences = .standard) {
        self.preferences = preferences
    }

    func load() -> UserPreferences {
        preferences
    }

    func save(_ preferences: UserPreferences) {
        self.preferences = preferences
    }
}
