import Foundation
import Testing
@testable import Workout_Pal

struct PreviousPerformanceTests {
    @Test func theMostRecentOtherWorkoutIsUsed() {
        let older = SampleData.session(
            startedAt: SampleData.daysAgo(7),
            exercises: [SampleData.exercise(sets: [SampleData.set(reps: 5, load: .kilograms(50))])]
        )
        let newer = SampleData.session(
            startedAt: SampleData.daysAgo(2),
            exercises: [SampleData.exercise(sets: [
                SampleData.set(reps: 8, load: .kilograms(60)),
                SampleData.set(reps: 8, load: .kilograms(60)),
                SampleData.set(reps: 8, load: .kilograms(60), isCompleted: false),
            ])]
        )
        let current = SampleData.session(status: .active)
        let sets = PreviousPerformance.latestSets(exerciseID: 1, in: [older, newer, current], excluding: current.id)
        #expect(sets?.count == 2)
        #expect(PreviousPerformance.summary(sets ?? [], units: .kilograms) == "Last time: 2 × 8 · 60 kg")
    }

    @Test func workoutsWithoutTheExerciseAreSkipped() {
        let withSquats = SampleData.session(startedAt: SampleData.daysAgo(5))
        let withoutSquats = SampleData.session(
            startedAt: SampleData.daysAgo(1),
            exercises: [SampleData.exercise(id: 2, name: "Lunges")]
        )
        let found = PreviousPerformance.latest(for: [1, 3], in: [withSquats, withoutSquats], excluding: UUID())
        #expect(found[1]?.count == 2)
        #expect(found[3] == nil)
    }

    @Test func theWorkoutBeingLoggedIsIgnored() {
        let current = SampleData.session()
        #expect(PreviousPerformance.latestSets(exerciseID: 1, in: [current], excluding: current.id) == nil)
    }

    @Test func differentRepsAreListed() {
        let sets = [
            SampleData.set(reps: 8, load: .bodyweight),
            SampleData.set(reps: 8, load: .bodyweight),
            SampleData.set(reps: 6, load: .bodyweight),
        ]
        #expect(PreviousPerformance.summary(sets, units: .kilograms) == "Last time: 8, 8, 6 reps · Bodyweight")
    }

    @Test func differentLoadsShowTheHeaviest() {
        let sets = [
            SampleData.set(reps: 5, load: .kilograms(60)),
            SampleData.set(reps: 5, load: .kilograms(70)),
        ]
        #expect(PreviousPerformance.summary(sets, units: .kilograms) == "Last time: 2 × 5 · up to 70 kg")
    }
}
