import Observation

@MainActor
@Observable
final class AppSettings {
    private(set) var preferences: UserPreferences
    private(set) var ownerID: String

    private let store: any PreferencesStore

    init(store: any PreferencesStore, ownerID: String = LocalProfile.ownerID) {
        self.store = store
        self.ownerID = ownerID
        preferences = store.load(ownerID: ownerID)
    }

    func update(_ change: (inout UserPreferences) -> Void) {
        change(&preferences)
        store.save(preferences, ownerID: ownerID)
    }

    func activate(ownerID: String, seedingFrom seedOwnerID: String? = nil) {
        if let seedOwnerID, seedOwnerID != ownerID, !store.hasPreferences(ownerID: ownerID) {
            store.save(store.load(ownerID: seedOwnerID), ownerID: ownerID)
        }
        self.ownerID = ownerID
        preferences = store.load(ownerID: ownerID)
    }

    func reset() {
        store.removePreferences(ownerID: ownerID)
        preferences = store.load(ownerID: ownerID)
    }
}
