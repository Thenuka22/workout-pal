import Foundation

enum SessionStatus: String, Sendable {
    case active
    case completed
}

enum SetSource: String, Sendable {
    case manual
    case camera
}

struct WorkoutSession: Identifiable, Hashable, Sendable {
    let id: UUID
    var ownerID: String
    var routineID: UUID?
    var routineName: String
    var startedAt: Date
    var endedAt: Date?
    var activeSeconds: Double
    var status: SessionStatus
    var notes: String
    var exercises: [SessionExercise]

    var completedSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }
}

struct SessionExercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var exerciseID: Int
    var exerciseName: String
    var sets: [WorkoutSet]
}

struct WorkoutSet: Identifiable, Hashable, Sendable {
    let id: UUID
    var reps: Int
    var load: Load
    var isCompleted: Bool
    var completedAt: Date?
    var source: SetSource
}
