protocol AccountDataRepository: Sendable {
    func reassignRecords(from oldOwnerID: String, to newOwnerID: String) async throws
    func deleteRecords(ownerID: String) async throws
}
