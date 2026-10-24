import Foundation
@testable import Workout_Pal

final class FakeHealthService: HealthService, @unchecked Sendable {
    var isAvailable = true
    var summary = HealthDaySummary(steps: 6_320, distanceMeters: 4_800, otherWorkouts: [])
    var failure: (any Error)?

    func todaySummary(now: Date) async throws -> HealthDaySummary {
        if let failure {
            throw failure
        }
        return summary
    }
}
