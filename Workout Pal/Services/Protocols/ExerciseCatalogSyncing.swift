import Foundation

protocol ExerciseCatalogSyncing: Sendable {
    func refresh(progress: @escaping @MainActor @Sendable (Int, Int) -> Void) async throws -> Int
    func lastRefresh() -> Date?
}
