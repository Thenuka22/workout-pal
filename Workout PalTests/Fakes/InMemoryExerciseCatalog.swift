import Foundation
@testable import Workout_Pal

actor InMemoryExerciseCatalogRepository: ExerciseCatalogRepository {
    private var stored: [Int: Exercise] = [:]

    init(_ exercises: [Exercise] = []) {
        for exercise in exercises {
            stored[exercise.id] = exercise
        }
    }

    func exercises() async throws -> [Exercise] {
        stored.values.sorted { $0.name < $1.name }
    }

    func exercise(id: Int) async throws -> Exercise? {
        stored[id]
    }

    func count() async throws -> Int {
        stored.count
    }

    func upsert(_ exercises: [Exercise]) async throws {
        for exercise in exercises {
            stored[exercise.id] = exercise
        }
    }
}

struct SeedingCatalogSync: ExerciseCatalogSyncing {
    let catalog: InMemoryExerciseCatalogRepository
    let exercises: [Exercise]

    func refresh(progress: @escaping @MainActor @Sendable (Int, Int) -> Void) async throws -> Int {
        try await catalog.upsert(exercises)
        return exercises.count
    }

    func lastRefresh() -> Date? {
        SampleData.now
    }
}

struct FakeCatalogSync: ExerciseCatalogSyncing {
    func refresh(progress: @escaping @MainActor @Sendable (Int, Int) -> Void) async throws -> Int {
        0
    }

    func lastRefresh() -> Date? {
        SampleData.now
    }
}
