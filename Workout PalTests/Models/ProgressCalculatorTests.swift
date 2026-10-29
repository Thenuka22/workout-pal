import Foundation
import Testing
@testable import Workout_Pal

struct ProgressCalculatorTests {
    @Test func walksAddStepsAndKnownDistancesToTheirWeek() {
        let buckets = ProgressCalculator.weekBuckets(
            sessions: [],
            activities: [
                SampleData.activity(startedAt: SampleData.now, steps: 3_000, distanceMeters: 2_000),
                SampleData.activity(startedAt: SampleData.daysAgo(1), steps: 1_500, distanceMeters: nil),
                SampleData.activity(startedAt: SampleData.daysAgo(8), steps: 4_000, distanceMeters: 3_100),
            ],
            weeks: 2,
            now: SampleData.now,
            calendar: SampleData.calendar
        )
        #expect(buckets.map(\.activities) == [1, 2])
        #expect(buckets.map(\.steps) == [4_000, 4_500])
        #expect(buckets.map(\.distanceMeters) == [3_100, 2_000])
        #expect(buckets.map(\.workouts) == [0, 0])
    }

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
        let walk = SampleData.activity(startedAt: SampleData.now.addingTimeInterval(60))
        let entries = HistoryEntry.merge(workouts: [older, newer], activities: [walk])
        let groups = ProgressCalculator.groupByWeek(entries: entries, calendar: SampleData.calendar)
        #expect(groups.count == 2)
        #expect(groups.first?.entries.map(\.id) == [walk.id, newer.id])
    }

    @Test func walksAddMinutesButNotWorkouts() {
        let buckets = ProgressCalculator.weekBuckets(
            sessions: [SampleData.session(minutes: 30)],
            activities: [SampleData.activity(minutes: 20)],
            weeks: 1,
            now: SampleData.now,
            calendar: SampleData.calendar
        )
        #expect(buckets.first?.workouts == 1)
        #expect(buckets.first?.activeMinutes == 50)
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
