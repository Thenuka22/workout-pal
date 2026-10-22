import Foundation

struct WeeklySummary: Hashable, Sendable {
    static let minutesPerWorkout = 30

    var workoutCount: Int
    var activeMinutes: Int
    var completedSets: Int
    var goal: Int
    var trainedWeekdays: Set<Int>
    var volumeKilograms: Double

    var goalProgress: Double {
        guard goal > 0 else {
            return 0
        }
        return min(Double(workoutCount) / Double(goal), 1)
    }

    var remainingWorkouts: Int {
        max(goal - workoutCount, 0)
    }

    var minutesTarget: Int {
        max(goal, 1) * Self.minutesPerWorkout
    }

    var minutesProgress: Double {
        min(Double(activeMinutes) / Double(minutesTarget), 1)
    }

    static let empty = WeeklySummary(
        workoutCount: 0,
        activeMinutes: 0,
        completedSets: 0,
        goal: 3,
        trainedWeekdays: [],
        volumeKilograms: 0
    )

    static func make(
        sessions: [WorkoutSession],
        goal: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WeeklySummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return WeeklySummary(
                workoutCount: 0,
                activeMinutes: 0,
                completedSets: 0,
                goal: goal,
                trainedWeekdays: [],
                volumeKilograms: 0
            )
        }
        let thisWeek = sessions.filter { $0.status == .completed && week.contains($0.startedAt) }
        let seconds = thisWeek.reduce(0.0) { $0 + $1.activeSeconds }
        let sets = thisWeek.reduce(0) { $0 + $1.completedSetCount }
        let weekdays = Set(thisWeek.map { calendar.component(.weekday, from: $0.startedAt) })
        let volume = thisWeek.reduce(0.0) { $0 + $1.loadedVolumeKilograms }
        return WeeklySummary(
            workoutCount: thisWeek.count,
            activeMinutes: Int((seconds / 60).rounded()),
            completedSets: sets,
            goal: goal,
            trainedWeekdays: weekdays,
            volumeKilograms: volume
        )
    }
}
