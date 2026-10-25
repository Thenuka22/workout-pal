import Foundation
@testable import Workout_Pal

actor InMemoryRoutineRepository: RoutineRepository {
    private var stored: [UUID: Routine] = [:]

    init(_ routines: [Routine] = []) {
        for routine in routines {
            stored[routine.id] = routine
        }
    }

    func routines(ownerID: String) async throws -> [Routine] {
        stored.values
            .filter { $0.ownerID == ownerID }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func routine(id: UUID) async throws -> Routine? {
        stored[id]
    }

    func save(_ routine: Routine) async throws {
        stored[routine.id] = routine
    }

    func deleteRoutine(id: UUID) async throws {
        stored[id] = nil
    }
}
