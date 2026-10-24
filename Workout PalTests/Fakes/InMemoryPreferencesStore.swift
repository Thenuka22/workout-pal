import Foundation
@testable import Workout_Pal

final class InMemoryPreferencesStore: PreferencesStore, @unchecked Sendable {
    private var stored: [String: UserPreferences] = [:]

    init(_ preferences: UserPreferences? = nil, ownerID: String = LocalProfile.ownerID) {
        if let preferences {
            stored[ownerID] = preferences
        }
    }

    func load(ownerID: String) -> UserPreferences {
        stored[ownerID] ?? .standard
    }

    func save(_ preferences: UserPreferences, ownerID: String) {
        stored[ownerID] = preferences
    }

    func hasPreferences(ownerID: String) -> Bool {
        stored[ownerID] != nil
    }

    func removePreferences(ownerID: String) {
        stored[ownerID] = nil
    }
}
