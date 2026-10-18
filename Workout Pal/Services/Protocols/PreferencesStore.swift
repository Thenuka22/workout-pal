protocol PreferencesStore: Sendable {
    func load() -> UserPreferences
    func save(_ preferences: UserPreferences)
}
