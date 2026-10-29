import Foundation
import Testing
@testable import Workout_Pal

struct ExerciseHistoryTests {
    @Test func oneRepMaxUsesTheEpleyFormula() {
        #expect(ExerciseHistory.estimatedOneRepMax(kilograms: 100, reps: 1) == 100)
        let estimate = ExerciseHistory.estimatedOneRepMax(kilograms: 90, reps: 10) ?? 0
        #expect(abs(estimate - 120) < 0.001)
    }

    @Test func oneRepMaxIsOnlyEstimatedForLowReps() {
        #expect(ExerciseHistory.estimatedOneRepMax(kilograms: 50, reps: 13) == nil)
        #expect(ExerciseHistory.estimatedOneRepMax(kilograms: 0, reps: 5) == nil)
        #expect(ExerciseHistory.estimatedOneRepMax(kilograms: 50, reps: 0) == nil)
    }

    @Test func entriesAreNewestFirstAndOnlyDoneSetsCount() {
        let older = SampleData.session(
            startedAt: SampleData.daysAgo(9),
            exercises: [SampleData.exercise(sets: [SampleData.set(reps: 3, load: .kilograms(100))])]
        )
        let newer = SampleData.session(
            startedAt: SampleData.daysAgo(2),
            exercises: [
                SampleData.exercise(sets: [
                    SampleData.set(reps: 10, load: .kilograms(90)),
                    SampleData.set(reps: 10, load: .kilograms(90), isCompleted: false),
                ]),
                SampleData.exercise(id: 2, name: "Lunges"),
            ]
        )
        let history = ExerciseHistory.make(exerciseID: 1, sessions: [older, newer])
        #expect(history.entries.map(\.id) == [newer.id, older.id])
        #expect(history.entries.first?.sets.count == 1)
        #expect(history.heaviest?.kilograms == 100)
        #expect(history.heaviest?.reps == 3)
        #expect(abs((history.bestOneRepMax?.kilograms ?? 0) - 120) < 0.001)
        #expect(history.bestOneRepMax?.date == newer.startedAt)
    }

    @Test func bodyweightSetsCountForRepsButNotOneRepMax() {
        let session = SampleData.session(
            exercises: [SampleData.exercise(sets: [SampleData.set(reps: 20, load: .bodyweight)])]
        )
        let history = ExerciseHistory.make(exerciseID: 1, sessions: [session])
        #expect(history.mostReps?.reps == 20)
        #expect(history.heaviest == nil)
        #expect(history.bestOneRepMax == nil)
    }

    @Test func anExerciseNeverDoneHasNoHistory() {
        let history = ExerciseHistory.make(exerciseID: 99, sessions: [SampleData.session()])
        #expect(history == .empty)
    }
}
