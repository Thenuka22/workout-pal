import Foundation
@testable import Workout_Pal

actor InMemoryActivitySessionRepository: ActivitySessionRepository {
    private var activities: [UUID: ActivitySession] = [:]

    init(_ activities: [ActivitySession] = []) {
        for activity in activities {
            self.activities[activity.id] = activity
        }
    }

    func stored(id: UUID) -> ActivitySession? {
        activities[id]
    }

    func completedActivities(ownerID: String) async throws -> [ActivitySession] {
        activities.values
            .filter { $0.ownerID == ownerID && $0.status == .completed }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func activeActivity(ownerID: String) async throws -> ActivitySession? {
        activities.values.first { $0.ownerID == ownerID && $0.status == .active }
    }

    func save(_ activity: ActivitySession) async throws {
        activities[activity.id] = activity
    }

    func updateHealthExport(id: UUID, status: HealthExportStatus) async throws {
        activities[id]?.healthExport = status
    }

    func deleteActivity(id: UUID) async throws {
        activities[id] = nil
    }
}
