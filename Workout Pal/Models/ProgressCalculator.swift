import Foundation

struct WeekBucket: Identifiable, Hashable, Sendable {
    let weekStart: Date
    var workouts: Int
    var activeMinutes: Int

    var id: Date { weekStart }
}

struct ExerciseProgressPoint: Identifiable, Hashable, Sendable {
    let date: Date
    let bestLoadKilograms: Double
    let bestReps: Int

    var id: Date { date }
}

struct ExerciseOption: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
}

struct HistoryGroup: Identifiable, Hashable, Sendable {
    let weekStart: Date
    let entries: [HistoryEntry]

    var id: Date { weekStart }
}

enum ProgressCalculator {
    static func weekBuckets(
        sessions: [WorkoutSession],
        activities: [ActivitySession] = [],
        weeks: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [WeekBucket] {
        guard weeks > 0, let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        var buckets: [WeekBucket] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            if let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeek.start) {
                buckets.append(WeekBucket(weekStart: start, workouts: 0, activeMinutes: 0))
            }
        }
        for session in sessions where session.status == .completed {
            if let index = buckets.firstIndex(where: {
                calendar.isDate($0.weekStart, equalTo: session.startedAt, toGranularity: .weekOfYear)
            }) {
                buckets[index].workouts += 1
                buckets[index].activeMinutes += Int((session.activeSeconds / 60).rounded())
            }
        }
        for activity in activities where activity.status == .completed {
            if let index = buckets.firstIndex(where: {
                calendar.isDate($0.weekStart, equalTo: activity.startedAt, toGranularity: .weekOfYear)
            }) {
                buckets[index].activeMinutes += Int((activity.activeSeconds / 60).rounded())
            }
        }
        return buckets
    }

    static func groupByWeek(entries: [HistoryEntry], calendar: Calendar = .current) -> [HistoryGroup] {
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .weekOfYear, for: entry.startedAt)?.start ?? entry.startedAt
        }
        return grouped
            .map { HistoryGroup(weekStart: $0.key, entries: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.weekStart > $1.weekStart }
    }

    static func exerciseOptions(sessions: [WorkoutSession]) -> [ExerciseOption] {
        var names: [Int: String] = [:]
        for session in sessions {
            for exercise in session.exercises {
                names[exercise.exerciseID] = exercise.exerciseName
            }
        }
        return names.map { ExerciseOption(id: $0.key, name: $0.value) }.sorted { $0.name < $1.name }
    }

    static func exerciseProgress(sessions: [WorkoutSession], exerciseID: Int) -> [ExerciseProgressPoint] {
        sessions
            .filter { $0.status == .completed }
            .compactMap { session -> ExerciseProgressPoint? in
                let completedSets = session.exercises
                    .filter { $0.exerciseID == exerciseID }
                    .flatMap(\.sets)
                    .filter(\.isCompleted)
                guard !completedSets.isEmpty else {
                    return nil
                }
                return ExerciseProgressPoint(
                    date: session.startedAt,
                    bestLoadKilograms: completedSets.compactMap(\.load.kilograms).max() ?? 0,
                    bestReps: completedSets.map(\.reps).max() ?? 0
                )
            }
            .sorted { $0.date < $1.date }
    }
}
