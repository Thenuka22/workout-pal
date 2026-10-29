import Foundation

/// What was logged for an exercise the last time it was done, shown as a hint while logging.
enum PreviousPerformance {
    static func latestSets(exerciseID: Int, in sessions: [WorkoutSession], excluding sessionID: UUID) -> [WorkoutSet]? {
        let ordered = sessions
            .filter { $0.status == .completed && $0.id != sessionID }
            .sorted { $0.startedAt > $1.startedAt }
        for session in ordered {
            let sets = session.exercises
                .filter { $0.exerciseID == exerciseID }
                .flatMap(\.sets)
                .filter(\.isCompleted)
            if !sets.isEmpty {
                return sets
            }
        }
        return nil
    }

    static func latest(for exerciseIDs: [Int], in sessions: [WorkoutSession], excluding sessionID: UUID) -> [Int: [WorkoutSet]] {
        var found: [Int: [WorkoutSet]] = [:]
        for exerciseID in exerciseIDs where found[exerciseID] == nil {
            if let sets = latestSets(exerciseID: exerciseID, in: sessions, excluding: sessionID) {
                found[exerciseID] = sets
            }
        }
        return found
    }

    static func summary(_ sets: [WorkoutSet], units: UnitPreference) -> String {
        "Last time: \(Formatting.sets(sets, units: units))"
    }
}
