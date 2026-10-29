import Foundation

struct ExerciseHistoryEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let workoutName: String
    let sets: [WorkoutSet]
}

struct ExerciseBest: Hashable, Sendable {
    let kilograms: Double
    let reps: Int
    let date: Date
}

/// Everything logged for one exercise, with its bests.
struct ExerciseHistory: Hashable, Sendable {
    static let empty = ExerciseHistory(entries: [], heaviest: nil, mostReps: nil, bestOneRepMax: nil)
    /// Above this many reps a one-rep-max estimate stops being meaningful.
    static let oneRepMaxRepLimit = 12

    let entries: [ExerciseHistoryEntry]
    let heaviest: ExerciseBest?
    let mostReps: ExerciseBest?
    let bestOneRepMax: ExerciseBest?

    /// Epley estimate of the heaviest single rep, in kilograms.
    static func estimatedOneRepMax(kilograms: Double, reps: Int) -> Double? {
        guard kilograms > 0, (1...oneRepMaxRepLimit).contains(reps) else {
            return nil
        }
        return reps == 1 ? kilograms : kilograms * (1 + Double(reps) / 30)
    }

    static func make(exerciseID: Int, sessions: [WorkoutSession]) -> ExerciseHistory {
        let entries = sessions
            .filter { $0.status == .completed }
            .compactMap { session -> ExerciseHistoryEntry? in
                let sets = session.exercises
                    .filter { $0.exerciseID == exerciseID }
                    .flatMap(\.sets)
                    .filter { $0.isCompleted && $0.reps > 0 }
                guard !sets.isEmpty else {
                    return nil
                }
                return ExerciseHistoryEntry(id: session.id, date: session.startedAt, workoutName: session.routineName, sets: sets)
            }
            .sorted { $0.date > $1.date }

        var heaviest: ExerciseBest?
        var mostReps: ExerciseBest?
        var bestOneRepMax: ExerciseBest?
        for entry in entries.reversed() {
            for set in entry.sets {
                let kilograms = set.load.kilograms ?? 0
                if kilograms > 0, kilograms > (heaviest?.kilograms ?? 0) {
                    heaviest = ExerciseBest(kilograms: kilograms, reps: set.reps, date: entry.date)
                }
                if set.reps > (mostReps?.reps ?? 0) {
                    mostReps = ExerciseBest(kilograms: kilograms, reps: set.reps, date: entry.date)
                }
                if let estimate = estimatedOneRepMax(kilograms: kilograms, reps: set.reps),
                   estimate > (bestOneRepMax?.kilograms ?? 0) {
                    bestOneRepMax = ExerciseBest(kilograms: estimate, reps: set.reps, date: entry.date)
                }
            }
        }
        return ExerciseHistory(entries: entries, heaviest: heaviest, mostReps: mostReps, bestOneRepMax: bestOneRepMax)
    }
}
