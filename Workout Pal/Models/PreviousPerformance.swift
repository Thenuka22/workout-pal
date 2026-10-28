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
        let reps = sets.map(\.reps)
        let repsText: String
        if let first = reps.first, reps.allSatisfy({ $0 == first }) {
            repsText = "\(sets.count) × \(first)"
        } else {
            repsText = reps.map(String.init).joined(separator: ", ") + " reps"
        }
        let loads = sets.map(\.load)
        let loadText: String
        if let first = loads.first, loads.allSatisfy({ $0 == first }) {
            loadText = Formatting.load(first, units: units)
        } else if let heaviest = loads.compactMap(\.kilograms).max() {
            loadText = "up to \(Formatting.load(.kilograms(heaviest), units: units))"
        } else {
            loadText = Formatting.load(.bodyweight, units: units)
        }
        return "Last time: \(repsText) · \(loadText)"
    }
}
