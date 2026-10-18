import Observation

@MainActor
@Observable
final class AppSettings {
    private(set) var preferences: UserPreferences

    private let store: any PreferencesStore

    init(store: any PreferencesStore) {
        self.store = store
        preferences = store.load()
    }

    func update(_ change: (inout UserPreferences) -> Void) {
        change(&preferences)
        store.save(preferences)
    }
}
