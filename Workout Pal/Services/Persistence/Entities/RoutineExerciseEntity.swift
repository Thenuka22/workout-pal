import CoreData
import Foundation

@objc(RoutineExerciseEntity)
class RoutineExerciseEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var exerciseID: Int64
    @NSManaged var exerciseName: String
    @NSManaged var sortOrder: Int16
    @NSManaged var plannedSets: Int16
    @NSManaged var plannedReps: Int16
    @NSManaged var plannedLoadKilograms: Double
    @NSManaged var isBodyweight: Bool
    @NSManaged var restSeconds: Int16
    @NSManaged var routine: RoutineEntity?
}
