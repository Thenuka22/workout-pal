import CoreData
import Foundation

@objc(WorkoutSessionEntity)
class WorkoutSessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ownerID: String
    @NSManaged var routineID: UUID?
    @NSManaged var routineName: String
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date?
    @NSManaged var activeSeconds: Double
    @NSManaged var status: String
    @NSManaged var notes: String
    @NSManaged var pausesData: Data?
    @NSManaged var healthExportStatus: String
    @NSManaged var exercises: NSSet?
}
