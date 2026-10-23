import Foundation

protocol ActivitySessionRepository: Sendable {
    func completedActivities(ownerID: String) async throws -> [ActivitySession]
    func activeActivity(ownerID: String) async throws -> ActivitySession?
    func save(_ activity: ActivitySession) async throws
    func updateHealthExport(id: UUID, status: HealthExportStatus) async throws
    func deleteActivity(id: UUID) async throws
}
