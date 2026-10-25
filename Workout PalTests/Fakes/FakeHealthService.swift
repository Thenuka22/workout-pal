import Foundation
@testable import Workout_Pal

final class FakeHealthService: HealthService, @unchecked Sendable {
    var isAvailable = true
    var summary = HealthDaySummary(steps: 6_320, distanceMeters: 4_800, otherWorkouts: [])
    var failure: (any Error)?
    var saveFailure: (any Error)?
    private(set) var savedWorkouts: [UUID: HealthWorkoutExport] = [:]
    private(set) var saveAttempts = 0

    func todaySummary(now: Date) async throws -> HealthDaySummary {
        if let failure {
            throw failure
        }
        return summary
    }

    func saveWorkout(_ workout: HealthWorkoutExport) async throws {
        saveAttempts += 1
        if let saveFailure {
            throw saveFailure
        }
        if savedWorkouts[workout.id] == nil {
            savedWorkouts[workout.id] = workout
        }
    }
}
