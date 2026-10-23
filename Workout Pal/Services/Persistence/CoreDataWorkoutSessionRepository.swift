import CoreData
import Foundation

struct CoreDataWorkoutSessionRepository: WorkoutSessionRepository {
    let stack: CoreDataStack

    func completedSessions(ownerID: String) async throws -> [WorkoutSession] {
        try await stack.perform { context in
            let request = NSFetchRequest<WorkoutSessionEntity>(entityName: "WorkoutSessionEntity")
            request.predicate = NSPredicate(
                format: "ownerID == %@ AND status == %@",
                argumentArray: [ownerID, SessionStatus.completed.rawValue]
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
            return try context.fetch(request).map { $0.toSession() }
        }
    }

    func activeSession(ownerID: String) async throws -> WorkoutSession? {
        try await stack.perform { context in
            let request = NSFetchRequest<WorkoutSessionEntity>(entityName: "WorkoutSessionEntity")
            request.predicate = NSPredicate(
                format: "ownerID == %@ AND status == %@",
                argumentArray: [ownerID, SessionStatus.active.rawValue]
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
            request.fetchLimit = 1
            return try context.fetch(request).first?.toSession()
        }
    }

    func session(id: UUID) async throws -> WorkoutSession? {
        try await stack.perform { context in
            try Self.entity(id: id, in: context)?.toSession()
        }
    }

    func save(_ session: WorkoutSession) async throws {
        try await stack.perform { context in
            let entity = try Self.entity(id: session.id, in: context) ?? WorkoutSessionEntity(context: context)
            entity.apply(session, in: context)
            try context.save()
        }
    }

    func updateHealthExport(id: UUID, status: HealthExportStatus) async throws {
        try await stack.perform { context in
            guard let entity = try Self.entity(id: id, in: context) else {
                return
            }
            entity.healthExportStatus = status.rawValue
            try context.save()
        }
    }

    func deleteSession(id: UUID) async throws {
        try await stack.perform { context in
            guard let entity = try Self.entity(id: id, in: context) else {
                return
            }
            context.delete(entity)
            try context.save()
        }
    }

    private static func entity(id: UUID, in context: NSManagedObjectContext) throws -> WorkoutSessionEntity? {
        let request = NSFetchRequest<WorkoutSessionEntity>(entityName: "WorkoutSessionEntity")
        request.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
