import Foundation
import Testing
@testable import Workout_Pal

struct WorkoutSessionTests {
    private let hour: TimeInterval = 3_600

    @Test func anOpenWorkoutGoesStaleAfterThreeQuietHours() {
        var session = SampleData.session(
            status: .active,
            exercises: [SampleData.exercise(sets: [SampleData.set(isCompleted: false)])]
        )
        #expect(!session.isStale(at: SampleData.now.addingTimeInterval(2 * hour)))
        #expect(session.isStale(at: SampleData.now.addingTimeInterval(4 * hour)))
        session.exercises[0].sets[0].isCompleted = true
        session.exercises[0].sets[0].completedAt = SampleData.now.addingTimeInterval(2 * hour)
        #expect(session.lastSetAt == SampleData.now.addingTimeInterval(2 * hour))
        #expect(!session.isStale(at: SampleData.now.addingTimeInterval(4 * hour)))
    }

    @Test func resumingCountsAsActivity() {
        var session = SampleData.session(
            status: .active,
            exercises: [SampleData.exercise(sets: [SampleData.set(isCompleted: false)])]
        )
        session.pauses = [PauseInterval(start: SampleData.now, end: SampleData.now.addingTimeInterval(3 * hour))]
        #expect(!session.isStale(at: SampleData.now.addingTimeInterval(4 * hour)))
    }

    @Test func pausedAndFinishedWorkoutsAreNeverStale() {
        var paused = SampleData.session(status: .active)
        paused.pauses = [PauseInterval(start: SampleData.now, end: nil)]
        #expect(!paused.isStale(at: SampleData.now.addingTimeInterval(10 * hour)))
        let finished = SampleData.session()
        #expect(!finished.isStale(at: SampleData.now.addingTimeInterval(10 * hour)))
    }
}
