import CoreData
import Foundation

actor CoreDataStack: PersistentStore {
    nonisolated(unsafe) private static let model: NSManagedObjectModel = {
        let bundle = Bundle(for: WorkoutSessionEntity.self)
        guard let url = bundle.url(forResource: "WorkoutPal", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url)
        else {
            return NSManagedObjectModel()
        }
        return model
    }()

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "WorkoutPal", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        self.container = container
    }

    func load() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func perform<T: Sendable>(_ work: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            return try work(context)
        }
    }
}
