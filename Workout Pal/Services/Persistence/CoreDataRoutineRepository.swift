import CoreData
import Foundation

struct CoreDataRoutineRepository: RoutineRepository {
    let stack: CoreDataStack

    func routines(ownerID: String) async throws -> [Routine] {
        try await stack.perform { context in
            let request = NSFetchRequest<RoutineEntity>(entityName: "RoutineEntity")
            request.predicate = NSPredicate(format: "ownerID == %@", argumentArray: [ownerID])
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            return try context.fetch(request).map { $0.toRoutine() }
        }
    }

    func routine(id: UUID) async throws -> Routine? {
        try await stack.perform { context in
            try Self.entity(id: id, in: context)?.toRoutine()
        }
    }

    func save(_ routine: Routine) async throws {
        try await stack.perform { context in
            let entity = try Self.entity(id: routine.id, in: context) ?? RoutineEntity(context: context)
            entity.apply(routine, in: context)
            try context.save()
        }
    }

    func deleteRoutine(id: UUID) async throws {
        try await stack.perform { context in
            guard let entity = try Self.entity(id: id, in: context) else {
                return
            }
            context.delete(entity)
            try context.save()
        }
    }

    private static func entity(id: UUID, in context: NSManagedObjectContext) throws -> RoutineEntity? {
        let request = NSFetchRequest<RoutineEntity>(entityName: "RoutineEntity")
        request.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
