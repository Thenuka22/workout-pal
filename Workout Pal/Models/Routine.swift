import Foundation

struct Routine: Identifiable, Hashable, Sendable {
    let id: UUID
    var ownerID: String
    var name: String
    var notes: String
    var exercises: [RoutineExercise]
    var createdAt: Date
    var updatedAt: Date
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
