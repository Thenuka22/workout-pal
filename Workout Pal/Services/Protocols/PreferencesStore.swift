protocol PreferencesStore: Sendable {
    func load(ownerID: String) -> UserPreferences
    func save(_ preferences: UserPreferences, ownerID: String)
    func hasPreferences(ownerID: String) -> Bool
    func removePreferences(ownerID: String)
}
