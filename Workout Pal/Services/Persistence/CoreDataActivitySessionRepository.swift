import CoreData
import Foundation

struct CoreDataActivitySessionRepository: ActivitySessionRepository {
    let stack: CoreDataStack

    func completedActivities(ownerID: String) async throws -> [ActivitySession] {
        try await stack.perform { context in
            let request = NSFetchRequest<ActivitySessionEntity>(entityName: "ActivitySessionEntity")
            request.predicate = NSPredicate(
                format: "ownerID == %@ AND status == %@",
                argumentArray: [ownerID, SessionStatus.completed.rawValue]
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
            return try context.fetch(request).map { $0.toActivity() }
        }
    }

    func activeActivity(ownerID: String) async throws -> ActivitySession? {
        try await stack.perform { context in
            let request = NSFetchRequest<ActivitySessionEntity>(entityName: "ActivitySessionEntity")
            request.predicate = NSPredicate(
                format: "ownerID == %@ AND status == %@",
                argumentArray: [ownerID, SessionStatus.active.rawValue]
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
            request.fetchLimit = 1
            return try context.fetch(request).first?.toActivity()
        }
    }

    func save(_ activity: ActivitySession) async throws {
        try await stack.perform { context in
            let entity = try Self.entity(id: activity.id, in: context) ?? ActivitySessionEntity(context: context)
            entity.apply(activity)
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

    func deleteActivity(id: UUID) async throws {
        try await stack.perform { context in
            guard let entity = try Self.entity(id: id, in: context) else {
                return
            }
            context.delete(entity)
            try context.save()
        }
    }

    private static func entity(id: UUID, in context: NSManagedObjectContext) throws -> ActivitySessionEntity? {
        let request = NSFetchRequest<ActivitySessionEntity>(entityName: "ActivitySessionEntity")
        request.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
