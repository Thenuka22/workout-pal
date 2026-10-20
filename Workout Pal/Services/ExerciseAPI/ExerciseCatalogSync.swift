import Foundation

struct ExerciseCatalogSync: ExerciseCatalogSyncing, @unchecked Sendable {
    static let pageSize = 100

    private let client: WgerClient
    private let catalog: any ExerciseCatalogRepository
    private let defaults: UserDefaults

    init(client: WgerClient, catalog: any ExerciseCatalogRepository, defaults: UserDefaults = .standard) {
        self.client = client
        self.catalog = catalog
        self.defaults = defaults
    }

    func refresh(progress: @escaping @MainActor @Sendable (Int, Int) -> Void) async throws -> Int {
        let now = Date.now
        var offset = 0
        var total = 0
        var imported = 0
        repeat {
            let page = try await client.fetchExercisePage(limit: Self.pageSize, offset: offset)
            total = page.count
            let exercises = page.results.compactMap { ExerciseMapper.exercise(from: $0, now: now) }
            try await catalog.upsert(exercises)
            imported += exercises.count
            offset += page.results.count
            await progress(min(offset, total), total)
            if page.next == nil || page.results.isEmpty {
                break
            }
        } while offset < total
        defaults.set(now, forKey: Self.lastRefreshKey)
        return imported
    }

    func lastRefresh() -> Date? {
        defaults.object(forKey: Self.lastRefreshKey) as? Date
    }

    private static let lastRefreshKey = "catalog.lastRefresh"
}
