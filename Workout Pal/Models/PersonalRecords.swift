import Foundation

enum RecordKind: String, Sendable {
    case heaviestLoad
    case mostReps

    var title: String {
        switch self {
        case .heaviestLoad: "Heaviest set"
        case .mostReps: "Most reps"
        }
    }
}

struct PersonalRecord: Identifiable, Hashable, Sendable {
    let exerciseID: Int
    let exerciseName: String
    let kind: RecordKind
    let value: Double
    let reps: Int
    let date: Date

    var id: String { "\(exerciseID)-\(kind.rawValue)" }
}

struct WorkoutFinishSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let routineName: String
    let activeSeconds: Double
    let completedSets: Int
    let volumeKilograms: Double
    let records: [PersonalRecord]

    init(session: WorkoutSession, records: [PersonalRecord]) {
        id = session.id
        routineName = session.routineName
        activeSeconds = session.activeSeconds
        completedSets = session.completedSetCount
        volumeKilograms = session.loadedVolumeKilograms
        self.records = records
    }
}

enum RecordBook {
    static func bests(sessions: [WorkoutSession]) -> [PersonalRecord] {
        var best: [String: PersonalRecord] = [:]
        let ordered = sessions
            .filter { $0.status == .completed }
            .sorted { $0.startedAt < $1.startedAt }
        for session in ordered {
            for record in candidates(in: session) {
                if let current = best[record.id], current.value >= record.value {
                    continue
                }
                best[record.id] = record
            }
        }
        return best.values.sorted { $0.date > $1.date }
    }

    static func newRecords(in session: WorkoutSession, previous: [WorkoutSession]) -> [PersonalRecord] {
        var earlier: [String: PersonalRecord] = [:]
        for record in bests(sessions: previous.filter { $0.id != session.id }) {
            earlier[record.id] = record
        }
        return candidates(in: session)
            .filter { record in
                guard let current = earlier[record.id] else {
                    return false
                }
                return record.value > current.value
            }
            .sorted { $0.exerciseName < $1.exerciseName }
    }

    static func candidates(in session: WorkoutSession) -> [PersonalRecord] {
        var records: [String: PersonalRecord] = [:]
        for exercise in session.exercises {
            let sets = exercise.sets.filter { $0.isCompleted && $0.reps > 0 }
            let loaded = sets.compactMap { set in set.load.kilograms.map { (kilograms: $0, reps: set.reps) } }
            if let heaviest = loaded.filter({ $0.kilograms > 0 }).max(by: { $0.kilograms < $1.kilograms }) {
                keepBest(PersonalRecord(
                    exerciseID: exercise.exerciseID,
                    exerciseName: exercise.exerciseName,
                    kind: .heaviestLoad,
                    value: heaviest.kilograms,
                    reps: heaviest.reps,
                    date: session.startedAt
                ), in: &records)
            }
            if let reps = sets.filter({ $0.load.isBodyweight }).map(\.reps).max() {
                keepBest(PersonalRecord(
                    exerciseID: exercise.exerciseID,
                    exerciseName: exercise.exerciseName,
                    kind: .mostReps,
                    value: Double(reps),
                    reps: reps,
                    date: session.startedAt
                ), in: &records)
            }
        }
        return Array(records.values)
    }

    private static func keepBest(_ record: PersonalRecord, in records: inout [String: PersonalRecord]) {
        if let current = records[record.id], current.value >= record.value {
            return
        }
        records[record.id] = record
    }
}

enum StreakCalculator {
    static func weekStreak(
        sessions: [WorkoutSession],
        goal: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard goal > 0, var weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return 0
        }
        let completed = sessions.filter { $0.status == .completed }
        let workouts = { (start: Date) -> Int in
            completed.filter { calendar.isDate($0.startedAt, equalTo: start, toGranularity: .weekOfYear) }.count
        }
        var streak = workouts(weekStart) >= goal ? 1 : 0
        while streak < 520, let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) {
            weekStart = previous
            guard workouts(weekStart) >= goal else {
                break
            }
            streak += 1
        }
        return streak
    }
}
