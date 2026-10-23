import Foundation
import Testing
@testable import Workout_Pal

struct ProgressCalculatorTests {
    @Test func weekBucketsEndWithTheCurrentWeek() {
        let sessions = [
            SampleData.session(startedAt: SampleData.now, minutes: 30),
            SampleData.session(startedAt: SampleData.daysAgo(1), minutes: 20),
            SampleData.session(startedAt: SampleData.daysAgo(14), minutes: 40),
            SampleData.session(startedAt: SampleData.daysAgo(60), minutes: 50),
        ]
        let buckets = ProgressCalculator.weekBuckets(
            sessions: sessions,
            weeks: 4,
            now: SampleData.now,
            calendar: SampleData.calendar
        )
        #expect(buckets.count == 4)
        #expect(buckets.map(\.workouts) == [0, 1, 0, 2])
        #expect(buckets.last?.activeMinutes == 50)
    }

    @Test func activeSessionsAreNotCharted() {
        let buckets = ProgressCalculator.weekBuckets(
            sessions: [SampleData.session(status: .active)],
            weeks: 1,
            now: SampleData.now,
            calendar: SampleData.calendar
        )
        #expect(buckets.first?.workouts == 0)
    }

    @Test func historyGroupsAreNewestFirst() {
        let older = SampleData.session(startedAt: SampleData.daysAgo(10))
        let newer = SampleData.session(startedAt: SampleData.now)
        let newest = SampleData.session(startedAt: SampleData.now.addingTimeInterval(60))
        let groups = ProgressCalculator.groupByWeek(sessions: [older, newer, newest], calendar: SampleData.calendar)
        #expect(groups.count == 2)
        #expect(groups.first?.sessions.map(\.id) == [newest.id, newer.id])
    }

    @Test func exerciseProgressTracksBestLoadAndReps() {
        let first = SampleData.session(startedAt: SampleData.daysAgo(7), exercises: [
            SampleData.exercise(id: 5, sets: [SampleData.set(reps: 8, load: .kilograms(40)), SampleData.set(reps: 10, load: .kilograms(35))]),
        ])
        let second = SampleData.session(startedAt: SampleData.now, exercises: [
            SampleData.exercise(id: 5, sets: [SampleData.set(reps: 6, load: .kilograms(45))]),
        ])
        let skipped = SampleData.session(startedAt: SampleData.daysAgo(3), exercises: [
            SampleData.exercise(id: 5, sets: [SampleData.set(isCompleted: false)]),
        ])
        let points = ProgressCalculator.exerciseProgress(sessions: [second, skipped, first], exerciseID: 5)
        #expect(points.map(\.bestLoadKilograms) == [40, 45])
        #expect(points.map(\.bestReps) == [10, 6])
    }

    @Test func exerciseOptionsAreUniqueAndSorted() {
        let sessions = [
            SampleData.session(exercises: [SampleData.exercise(id: 2, name: "Rows"), SampleData.exercise(id: 1, name: "Bench press")]),
            SampleData.session(exercises: [SampleData.exercise(id: 2, name: "Rows")]),
        ]
        let options = ProgressCalculator.exerciseOptions(sessions: sessions)
        #expect(options.map(\.name) == ["Bench press", "Rows"])
    }
}
