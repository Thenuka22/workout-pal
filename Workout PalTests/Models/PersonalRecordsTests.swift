import Foundation
import Testing
@testable import Workout_Pal

struct RecordBookTests {
    private func bench(_ sets: [WorkoutSet], daysAgo: Int) -> WorkoutSession {
        SampleData.session(
            startedAt: SampleData.daysAgo(daysAgo),
            exercises: [SampleData.exercise(id: 10, name: "Bench Press", sets: sets)]
        )
    }

    private func pushUps(_ reps: [Int], daysAgo: Int) -> WorkoutSession {
        SampleData.session(
            startedAt: SampleData.daysAgo(daysAgo),
            exercises: [SampleData.exercise(id: 20, name: "Push-Ups", sets: reps.map { SampleData.set(reps: $0, load: .bodyweight) })]
        )
    }

    @Test func bestsKeepTheHeaviestSet() throws {
        let sessions = [
            bench([SampleData.set(reps: 8, load: .kilograms(40))], daysAgo: 7),
            bench([SampleData.set(reps: 6, load: .kilograms(45)), SampleData.set(reps: 10, load: .kilograms(35))], daysAgo: 2),
        ]
        let record = try #require(RecordBook.bests(sessions: sessions).first { $0.kind == .heaviestLoad })
        #expect(record.value == 45)
        #expect(record.reps == 6)
        #expect(record.exerciseName == "Bench Press")
    }

    @Test func bodyweightSetsTrackMostReps() throws {
        let sessions = [pushUps([15, 12], daysAgo: 5), pushUps([12], daysAgo: 1)]
        let record = try #require(RecordBook.bests(sessions: sessions).first)
        #expect(record.kind == .mostReps)
        #expect(record.value == 15)
        #expect(RecordBook.bests(sessions: sessions).count == 1)
    }

    @Test func unfinishedSetsAreIgnored() {
        let session = bench([SampleData.set(reps: 5, load: .kilograms(100), isCompleted: false)], daysAgo: 1)
        #expect(RecordBook.bests(sessions: [session]).isEmpty)
    }

    @Test func beatingAnEarlierBestIsANewRecord() {
        let earlier = bench([SampleData.set(reps: 8, load: .kilograms(40))], daysAgo: 7)
        let today = bench([SampleData.set(reps: 5, load: .kilograms(42.5))], daysAgo: 0)
        let records = RecordBook.newRecords(in: today, previous: [earlier, today])
        #expect(records.map(\.value) == [42.5])
    }

    @Test func matchingTheBestIsNotARecord() {
        let earlier = pushUps([15], daysAgo: 7)
        let today = pushUps([15], daysAgo: 0)
        #expect(RecordBook.newRecords(in: today, previous: [earlier]).isEmpty)
    }

    @Test func aFirstEverExerciseIsNotARecord() {
        let today = bench([SampleData.set(reps: 5, load: .kilograms(60))], daysAgo: 0)
        #expect(RecordBook.newRecords(in: today, previous: []).isEmpty)
    }
}

struct StreakCalculatorTests {
    private func workouts(daysAgo: [Int]) -> [WorkoutSession] {
        daysAgo.map { SampleData.session(startedAt: SampleData.daysAgo($0)) }
    }

    private func streak(_ sessions: [WorkoutSession], goal: Int) -> Int {
        StreakCalculator.weekStreak(sessions: sessions, goal: goal, now: SampleData.now, calendar: SampleData.calendar)
    }

    @Test func countsThisWeekWhenTheGoalIsMet() {
        let sessions = workouts(daysAgo: [0, 1, 7, 8, 14])
        #expect(streak(sessions, goal: 2) == 2)
    }

    @Test func anUnfinishedWeekDoesNotBreakTheStreak() {
        let sessions = workouts(daysAgo: [0, 7, 8, 14, 15])
        #expect(streak(sessions, goal: 2) == 2)
    }

    @Test func aMissedWeekEndsTheStreak() {
        let sessions = workouts(daysAgo: [0, 1, 14, 15])
        #expect(streak(sessions, goal: 2) == 1)
    }

    @Test func noWorkoutsMeansNoStreak() {
        #expect(streak([], goal: 3) == 0)
        #expect(streak(workouts(daysAgo: [0]), goal: 0) == 0)
    }

    @Test func unfinishedWorkoutsDoNotCount() {
        let sessions = [SampleData.session(status: .active), SampleData.session(startedAt: SampleData.daysAgo(1), status: .active)]
        #expect(streak(sessions, goal: 1) == 0)
    }
}
