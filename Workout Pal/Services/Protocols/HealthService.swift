import Foundation

protocol HealthService: Sendable {
    var isAvailable: Bool { get }
    func todaySummary(now: Date) async throws -> HealthDaySummary
    func saveWorkout(_ workout: HealthWorkoutExport) async throws
}
