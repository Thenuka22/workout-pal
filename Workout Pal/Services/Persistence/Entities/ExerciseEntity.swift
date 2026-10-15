import CoreData
import Foundation

@objc(ExerciseEntity)
class ExerciseEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var uuid: String
    @NSManaged var name: String
    @NSManaged var summary: String
    @NSManaged var category: String
    @NSManaged var primaryMuscles: String
    @NSManaged var secondaryMuscles: String
    @NSManaged var equipment: String
    @NSManaged var imageURL: String?
    @NSManaged var licenseName: String
    @NSManaged var licenseURL: String?
    @NSManaged var licenseAuthor: String
    @NSManaged var updatedAt: Date
}
