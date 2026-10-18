import Foundation

struct WeeklySummary: Hashable, Sendable {
    var workoutCount: Int
    var activeMinutes: Int
    var completedSets: Int
    var goal: Int

    var goalProgress: Double {
        guard goal > 0 else {
            return 0
        }
        return min(Double(workoutCount) / Double(goal), 1)
    }

    static let empty = WeeklySummary(workoutCount: 0, activeMinutes: 0, completedSets: 0, goal: 3)

    static func make(
        sessions: [WorkoutSession],
        goal: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WeeklySummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return WeeklySummary(workoutCount: 0, activeMinutes: 0, completedSets: 0, goal: goal)
        }
        let thisWeek = sessions.filter { $0.status == .completed && week.contains($0.startedAt) }
        let seconds = thisWeek.reduce(0.0) { $0 + $1.activeSeconds }
        let sets = thisWeek.reduce(0) { $0 + $1.completedSetCount }
        return WeeklySummary(
            workoutCount: thisWeek.count,
            activeMinutes: Int((seconds / 60).rounded()),
            completedSets: sets,
            goal: goal
        )
    }
}
