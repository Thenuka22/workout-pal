import Foundation

struct Routine: Identifiable, Hashable, Sendable {
    let id: UUID
    var ownerID: String
    var name: String
    var notes: String
    var exercises: [RoutineExercise]
    var createdAt: Date
    var updatedAt: Date

    var plannedSetCount: Int {
        exercises.reduce(0) { $0 + $1.plannedSets }
    }

    var estimatedMinutes: Int {
        let seconds = exercises.reduce(0) { total, exercise in
            total + exercise.plannedSets * (exercise.plannedReps * 3 + exercise.restSeconds)
        }
        guard seconds > 0 else {
            return 0
        }
        return max(Int((Double(seconds) / 60).rounded()), 1)
    }
}

struct RoutineExercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var exerciseID: Int
    var exerciseName: String
    var plannedSets: Int
    var plannedReps: Int
    var plannedLoad: Load
    var restSeconds: Int
}
