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
    static let staleAfter: TimeInterval = 3 * 60 * 60

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
    var pauses: [PauseInterval] = []
    var healthExport: HealthExportStatus = .notExported

    var isPaused: Bool {
        SessionTiming.isPaused(pauses)
    }

    func activeSeconds(at now: Date) -> Double {
        SessionTiming.activeSeconds(startedAt: startedAt, endedAt: endedAt, pauses: pauses, now: now)
    }

    var lastSetAt: Date? {
        exercises.flatMap(\.sets).compactMap(\.completedAt).max()
    }

    var lastActivityAt: Date {
        let resumes = pauses.compactMap(\.end)
        return ([startedAt] + resumes + [lastSetAt].compactMap { $0 }).max() ?? startedAt
    }

    /// An open workout nobody has touched for hours, usually because the app was closed mid-session.
    func isStale(at date: Date) -> Bool {
        status == .active && !isPaused && date.timeIntervalSince(lastActivityAt) > Self.staleAfter
    }

    var totalSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var completedSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    var loadedVolumeKilograms: Double {
        exercises
            .flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0) { total, set in
                guard let kilograms = set.load.kilograms else {
                    return total
                }
                return total + kilograms * Double(set.reps)
            }
    }
}

struct SessionExercise: Identifiable, Hashable, Sendable {
    let id: UUID
    var exerciseID: Int
    var exerciseName: String
    var restSeconds: Int
    var sets: [WorkoutSet]

    var completedSetCount: Int {
        sets.filter(\.isCompleted).count
    }
}

struct WorkoutSet: Identifiable, Hashable, Sendable {
    let id: UUID
    var reps: Int
    var load: Load
    var isCompleted: Bool
    var completedAt: Date?
    var source: SetSource
}
