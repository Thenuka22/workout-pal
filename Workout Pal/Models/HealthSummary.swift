import Foundation

struct HealthWorkoutSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let startedAt: Date
    let durationSeconds: Double
    let sourceName: String
}

struct HealthDaySummary: Hashable, Sendable {
    static let dailyStepGoal = 8_000

    var steps: Int?
    var distanceMeters: Double?
    var otherWorkouts: [HealthWorkoutSummary]

    var stepProgress: Double {
        guard let steps else {
            return 0
        }
        return min(Double(steps) / Double(Self.dailyStepGoal), 1)
    }
}

enum HealthCardState: Equatable {
    case unavailable
    case notConnected
    case loading
    case loaded(HealthDaySummary, updatedAt: Date)
    case failed(String)
}
