import CoreData
import Foundation

@objc(RoutineEntity)
class RoutineEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ownerID: String
    @NSManaged var name: String
    @NSManaged var notes: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var exercises: NSSet?
}
