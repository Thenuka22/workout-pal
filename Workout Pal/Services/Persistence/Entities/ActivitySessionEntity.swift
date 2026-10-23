import CoreData
import Foundation

@objc(ActivitySessionEntity)
class ActivitySessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ownerID: String
    @NSManaged var kind: String
    @NSManaged var status: String
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date?
    @NSManaged var pausesData: Data?
    @NSManaged var steps: Int64
    @NSManaged var distanceMeters: Double
    @NSManaged var hasDistance: Bool
    @NSManaged var detectedMotion: String?
    @NSManaged var healthExportStatus: String
}
