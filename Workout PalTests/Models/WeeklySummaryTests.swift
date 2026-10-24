import Foundation
import Testing
@testable import Workout_Pal

struct WeeklySummaryTests {
    private let monday = SampleData.date(year: 2026, month: 10, day: 19, hour: 7)
    private let previousSunday = SampleData.date(year: 2026, month: 10, day: 18, hour: 18)

    private func summary(_ sessions: [WorkoutSession], goal: Int = 3) -> WeeklySummary {
        WeeklySummary.make(sessions: sessions, goal: goal, now: SampleData.now, calendar: SampleData.calendar)
    }

    @Test func countsOnlyCompletedWorkoutsFromThisWeek() {
        let sessions = [
            SampleData.session(startedAt: monday, minutes: 30),
            SampleData.session(startedAt: SampleData.now, status: .active),
            SampleData.session(startedAt: previousSunday, minutes: 45),
        ]
        let result = summary(sessions)
        #expect(result.workoutCount == 1)
        #expect(result.activeMinutes == 30)
        #expect(result.trainedWeekdays == [2])
    }

    @Test func volumeUsesCompletedLoadedSetsOnly() {
        let exercise = SampleData.exercise(sets: [
            SampleData.set(reps: 10, load: .kilograms(20)),
            SampleData.set(reps: 8, load: .kilograms(25)),
            SampleData.set(reps: 12, load: .bodyweight),
            SampleData.set(reps: 10, load: .kilograms(100), isCompleted: false),
        ])
        let result = summary([SampleData.session(startedAt: monday, exercises: [exercise])])
        #expect(result.volumeKilograms == 400)
        #expect(result.completedSets == 3)
    }

    @Test func goalProgressIsCappedAtComplete() {
        let sessions = (0..<4).map { offset in
            SampleData.session(startedAt: monday.addingTimeInterval(Double(offset) * 3_600))
        }
        let result = summary(sessions, goal: 2)
        #expect(result.goalProgress == 1)
        #expect(result.remainingWorkouts == 0)
    }

    @Test func walksCountTowardsMinutesAndSteps() {
        let walk = SampleData.activity(startedAt: monday, minutes: 25, steps: 3_100)
        let oldWalk = SampleData.activity(startedAt: previousSunday, minutes: 40, steps: 5_000)
        let result = WeeklySummary.make(
            sessions: [SampleData.session(startedAt: monday, minutes: 30)],
            activities: [walk, oldWalk],
            goal: 3,
            now: SampleData.now,
            calendar: SampleData.calendar
        )
        #expect(result.workoutCount == 1)
        #expect(result.activeMinutes == 55)
        #expect(result.steps == 3_100)
    }

    @Test func emptyWeekStillReportsTheGoal() {
        let result = summary([], goal: 4)
        #expect(result.workoutCount == 0)
        #expect(result.goal == 4)
        #expect(result.remainingWorkouts == 4)
        #expect(result.minutesTarget == 4 * WeeklySummary.minutesPerWorkout)
    }
}
