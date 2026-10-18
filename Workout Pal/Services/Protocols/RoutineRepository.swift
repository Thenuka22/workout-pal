import Foundation

protocol RoutineRepository: Sendable {
    func routines(ownerID: String) async throws -> [Routine]
    func routine(id: UUID) async throws -> Routine?
    func save(_ routine: Routine) async throws
    func deleteRoutine(id: UUID) async throws
}
