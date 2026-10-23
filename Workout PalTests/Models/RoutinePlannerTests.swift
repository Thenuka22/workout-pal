import Foundation
import Testing
@testable import Workout_Pal

struct RoutinePlannerTests {
    @Test func suggestsARoutineThatWasNeverDone() {
        let done = SampleData.routine(name: "Push")
        let fresh = SampleData.routine(name: "Pull")
        let sessions = [SampleData.session(routineID: done.id)]
        let next = RoutinePlanner.nextRoutine(from: [done, fresh], sessions: sessions)
        #expect(next?.id == fresh.id)
    }

    @Test func suggestsTheLeastRecentlyCompletedRoutine() {
        let push = SampleData.routine(name: "Push")
        let pull = SampleData.routine(name: "Pull")
        let sessions = [
            SampleData.session(startedAt: SampleData.daysAgo(1), routineID: push.id),
            SampleData.session(startedAt: SampleData.daysAgo(5), routineID: pull.id),
        ]
        #expect(RoutinePlanner.nextRoutine(from: [push, pull], sessions: sessions)?.id == pull.id)
    }

    @Test func ignoresUnfinishedWorkouts() {
        let push = SampleData.routine(name: "Push", createdAt: SampleData.daysAgo(10))
        let pull = SampleData.routine(name: "Pull", createdAt: SampleData.daysAgo(2))
        let sessions = [SampleData.session(status: .active, routineID: push.id)]
        #expect(RoutinePlanner.nextRoutine(from: [push, pull], sessions: sessions)?.id == push.id)
    }

    @Test func returnsNothingWithoutRoutines() {
        #expect(RoutinePlanner.nextRoutine(from: [], sessions: []) == nil)
    }
}
