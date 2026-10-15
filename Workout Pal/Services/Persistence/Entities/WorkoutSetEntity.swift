import CoreData
import Foundation

@objc(WorkoutSetEntity)
class WorkoutSetEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var sortOrder: Int16
    @NSManaged var reps: Int16
    @NSManaged var loadKilograms: Double
    @NSManaged var isBodyweight: Bool
    @NSManaged var isCompleted: Bool
    @NSManaged var completedAt: Date?
    @NSManaged var source: String
    @NSManaged var exercise: SessionExerciseEntity?
}
