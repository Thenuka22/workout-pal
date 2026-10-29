import Foundation

/// Plain-text summary of a finished session for the share sheet.
enum ShareSummary {
    static func text(for entry: HistoryEntry, units: UnitPreference) -> String {
        switch entry {
        case .workout(let session): workout(session, units: units)
        case .activity(let walk): activity(walk, units: units)
        }
    }

    private static func workout(_ session: WorkoutSession, units: UnitPreference) -> String {
        var lines = ["\(session.routineName) · \(Formatting.date(session.startedAt))"]
        var stats = [
            Formatting.minutes(fromSeconds: session.activeSeconds),
            Formatting.count(session.completedSetCount, "set"),
        ]
        if session.loadedVolumeKilograms > 0 {
            stats.append("\(Formatting.volume(kilograms: session.loadedVolumeKilograms, units: units)) lifted")
        }
        lines.append(stats.joined(separator: " · "))
        for exercise in session.exercises {
            let done = exercise.sets.filter(\.isCompleted)
            if !done.isEmpty {
                lines.append("\(exercise.exerciseName): \(Formatting.sets(done, units: units))")
            }
        }
        lines.append("Logged with Workout Pal")
        return lines.joined(separator: "\n")
    }

    private static func activity(_ activity: ActivitySession, units: UnitPreference) -> String {
        var stats = [
            Formatting.minutes(fromSeconds: activity.activeSeconds),
            "\(Formatting.steps(activity.steps)) steps",
        ]
        if let meters = activity.distanceMeters {
            stats.append("\(Formatting.distance(meters: meters, units: units)) (estimated)")
        }
        return [
            "\(activity.kind.title) · \(Formatting.date(activity.startedAt))",
            stats.joined(separator: " · "),
            "Logged with Workout Pal",
        ].joined(separator: "\n")
    }
}
