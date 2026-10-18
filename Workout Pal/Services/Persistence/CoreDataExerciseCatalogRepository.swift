import CoreData
import Foundation

struct CoreDataExerciseCatalogRepository: ExerciseCatalogRepository {
    let stack: CoreDataStack

    func exercises() async throws -> [Exercise] {
        try await stack.perform { context in
            let request = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request).map { $0.toExercise() }
        }
    }

    func exercise(id: Int) async throws -> Exercise? {
        try await stack.perform { context in
            let request = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
            request.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
            request.fetchLimit = 1
            return try context.fetch(request).first?.toExercise()
        }
    }

    func count() async throws -> Int {
        try await stack.perform { context in
            let request = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
            return try context.count(for: request)
        }
    }

    func upsert(_ exercises: [Exercise]) async throws {
        guard !exercises.isEmpty else {
            return
        }
        try await stack.perform { context in
            let ids = exercises.map(\.id)
            let request = NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
            request.predicate = NSPredicate(format: "id IN %@", argumentArray: [ids])
            var existing: [Int: ExerciseEntity] = [:]
            for entity in try context.fetch(request) {
                existing[Int(entity.id)] = entity
            }
            for exercise in exercises {
                let entity = existing[exercise.id] ?? ExerciseEntity(context: context)
                entity.apply(exercise)
            }
            try context.save()
        }
    }
}
