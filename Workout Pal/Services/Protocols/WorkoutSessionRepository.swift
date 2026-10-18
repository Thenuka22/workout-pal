import Foundation

protocol WorkoutSessionRepository: Sendable {
    func completedSessions(ownerID: String) async throws -> [WorkoutSession]
    func activeSession(ownerID: String) async throws -> WorkoutSession?
    func session(id: UUID) async throws -> WorkoutSession?
    func save(_ session: WorkoutSession) async throws
    func deleteSession(id: UUID) async throws
}
