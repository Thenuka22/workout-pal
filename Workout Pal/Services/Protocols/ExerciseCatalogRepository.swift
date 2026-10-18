protocol ExerciseCatalogRepository: Sendable {
    func exercises() async throws -> [Exercise]
    func exercise(id: Int) async throws -> Exercise?
    func count() async throws -> Int
    func upsert(_ exercises: [Exercise]) async throws
}
