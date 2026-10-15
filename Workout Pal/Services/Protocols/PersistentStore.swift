protocol PersistentStore: Sendable {
    func load() async throws
}
