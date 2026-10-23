import Foundation
@testable import Workout_Pal

enum SampleData {
    static let ownerID = "owner-a"

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    static let now: Date = date(year: 2026, month: 10, day: 21, hour: 12)

    static func date(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }

    static func daysAgo(_ days: Int, from date: Date = SampleData.now) -> Date {
        calendar.date(byAdding: .day, value: -days, to: date) ?? date
    }

    static func set(
        reps: Int = 10,
        load: Load = .kilograms(20),
        isCompleted: Bool = true,
        source: SetSource = .manual
    ) -> WorkoutSet {
        WorkoutSet(
            id: UUID(),
            reps: reps,
            load: load,
            isCompleted: isCompleted,
            completedAt: isCompleted ? SampleData.now : nil,
            source: source
        )
    }

    static func exercise(id: Int = 1, name: String = "Squats", sets: [WorkoutSet] = [SampleData.set(), SampleData.set()]) -> SessionExercise {
        SessionExercise(id: UUID(), exerciseID: id, exerciseName: name, restSeconds: 60, sets: sets)
    }

    static func session(
        startedAt: Date = SampleData.now,
        minutes: Double = 30,
        status: SessionStatus = .completed,
        ownerID: String = SampleData.ownerID,
        routineID: UUID? = nil,
        name: String = "Leg day",
        exercises: [SessionExercise] = [SampleData.exercise()]
    ) -> WorkoutSession {
        WorkoutSession(
            id: UUID(),
            ownerID: ownerID,
            routineID: routineID,
            routineName: name,
            startedAt: startedAt,
            endedAt: status == .completed ? startedAt.addingTimeInterval(minutes * 60) : nil,
            activeSeconds: status == .completed ? minutes * 60 : 0,
            status: status,
            notes: "",
            exercises: exercises
        )
    }

    static func routineExercise(
        id: Int = 1,
        name: String = "Squats",
        sets: Int = 3,
        reps: Int = 10,
        load: Load = .bodyweight,
        rest: Int = 60
    ) -> RoutineExercise {
        RoutineExercise(
            id: UUID(),
            exerciseID: id,
            exerciseName: name,
            plannedSets: sets,
            plannedReps: reps,
            plannedLoad: load,
            restSeconds: rest
        )
    }

    static func routine(
        name: String = "Leg day",
        ownerID: String = SampleData.ownerID,
        createdAt: Date = SampleData.now,
        exercises: [RoutineExercise] = [SampleData.routineExercise()]
    ) -> Routine {
        Routine(
            id: UUID(),
            ownerID: ownerID,
            name: name,
            notes: "",
            exercises: exercises,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    static func activity(
        kind: ActivityKind = .walk,
        startedAt: Date = SampleData.now,
        minutes: Double = 20,
        steps: Int = 2_400,
        distanceMeters: Double? = 1_800,
        ownerID: String = SampleData.ownerID
    ) -> ActivitySession {
        ActivitySession(
            id: UUID(),
            ownerID: ownerID,
            kind: kind,
            status: .completed,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(minutes * 60),
            pauses: [],
            steps: steps,
            distanceMeters: distanceMeters,
            detectedMotion: .walking,
            healthExport: .notExported
        )
    }
}
