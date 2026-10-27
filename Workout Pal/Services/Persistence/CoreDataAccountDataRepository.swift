import CoreData
import Foundation

struct CoreDataAccountDataRepository: AccountDataRepository {
    static let ownedEntityNames = ["RoutineEntity", "WorkoutSessionEntity", "ActivitySessionEntity"]

    let stack: CoreDataStack

    func reassignRecords(from oldOwnerID: String, to newOwnerID: String) async throws {
        guard oldOwnerID != newOwnerID else {
            return
        }
        try await stack.perform { context in
            for entityName in Self.ownedEntityNames {
                for object in try Self.objects(named: entityName, ownerID: oldOwnerID, in: context) {
                    object.setValue(newOwnerID, forKey: "ownerID")
                }
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func deleteRecords(ownerID: String) async throws {
        try await stack.perform { context in
            for entityName in Self.ownedEntityNames {
                for object in try Self.objects(named: entityName, ownerID: ownerID, in: context) {
                    context.delete(object)
                }
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func pauseUnfinishedSessions(ownerID: String, at date: Date) async throws {
        let workouts = CoreDataWorkoutSessionRepository(stack: stack)
        if var workout = try await workouts.activeSession(ownerID: ownerID), !workout.isPaused {
            workout.pauses = SessionTiming.pausing(workout.pauses, at: date)
            try await workouts.save(workout)
        }
        let activities = CoreDataActivitySessionRepository(stack: stack)
        if var activity = try await activities.activeActivity(ownerID: ownerID), !activity.isPaused {
            activity.pauses = SessionTiming.pausing(activity.pauses, at: date)
            try await activities.save(activity)
        }
    }

    private static func objects(
        named entityName: String,
        ownerID: String,
        in context: NSManagedObjectContext
    ) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "ownerID == %@", argumentArray: [ownerID])
        return try context.fetch(request)
    }
}
