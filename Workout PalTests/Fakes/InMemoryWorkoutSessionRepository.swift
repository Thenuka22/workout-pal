import Foundation
@testable import Workout_Pal

actor InMemoryWorkoutSessionRepository: WorkoutSessionRepository {
    private var sessions: [UUID: WorkoutSession] = [:]
    private var failure: (any Error)?
    private(set) var saveCount = 0

    init(_ sessions: [WorkoutSession] = []) {
        for session in sessions {
            self.sessions[session.id] = session
        }
    }

    func failSaves(with error: (any Error)?) {
        failure = error
    }

    func stored(id: UUID) -> WorkoutSession? {
        sessions[id]
    }

    func completedSessions(ownerID: String) async throws -> [WorkoutSession] {
        sessions.values
            .filter { $0.ownerID == ownerID && $0.status == .completed }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func activeSession(ownerID: String) async throws -> WorkoutSession? {
        sessions.values.first { $0.ownerID == ownerID && $0.status == .active }
    }

    func session(id: UUID) async throws -> WorkoutSession? {
        sessions[id]
    }

    func save(_ session: WorkoutSession) async throws {
        if let failure {
            throw failure
        }
        saveCount += 1
        sessions[session.id] = session
    }

    func updateHealthExport(id: UUID, status: HealthExportStatus) async throws {
        sessions[id]?.healthExport = status
    }

    func deleteSession(id: UUID) async throws {
        sessions[id] = nil
    }
}
