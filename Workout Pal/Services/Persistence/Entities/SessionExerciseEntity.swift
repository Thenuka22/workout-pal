import CoreData
import Foundation

@objc(SessionExerciseEntity)
class SessionExerciseEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var exerciseID: Int64
    @NSManaged var exerciseName: String
    @NSManaged var restSeconds: Int16
    @NSManaged var sortOrder: Int16
    @NSManaged var session: WorkoutSessionEntity?
    @NSManaged var sets: NSSet?
}
