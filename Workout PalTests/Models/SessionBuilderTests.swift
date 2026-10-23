import Foundation
import Testing
@testable import Workout_Pal

struct SessionBuilderTests {
    @Test func buildsAnActiveSessionFromThePlan() {
        let routine = SampleData.routine(exercises: [
            SampleData.routineExercise(id: 1, name: "Squats", sets: 3, reps: 12, load: .bodyweight, rest: 45),
            SampleData.routineExercise(id: 2, name: "Deadlift", sets: 2, reps: 5, load: .kilograms(80), rest: 120),
        ])
        let session = SessionBuilder.session(from: routine, ownerID: SampleData.ownerID, now: SampleData.now)
        #expect(session.status == .active)
        #expect(session.routineID == routine.id)
        #expect(session.routineName == "Leg day")
        #expect(session.startedAt == SampleData.now)
        #expect(session.exercises.map(\.exerciseName) == ["Squats", "Deadlift"])
        #expect(session.exercises.map(\.sets.count) == [3, 2])
        #expect(session.exercises[1].sets.allSatisfy { $0.reps == 5 && $0.load == .kilograms(80) && !$0.isCompleted })
        #expect(session.exercises[0].restSeconds == 45)
        #expect(session.pauses.isEmpty)
        #expect(session.healthExport == .notExported)
    }

    @Test func alwaysCreatesAtLeastOneSet() {
        let routine = SampleData.routine(exercises: [SampleData.routineExercise(sets: 0)])
        let session = SessionBuilder.session(from: routine, ownerID: SampleData.ownerID)
        #expect(session.exercises.first?.sets.count == 1)
    }

    @Test func laterRoutineEditsDoNotChangeTheSession() {
        var routine = SampleData.routine()
        let session = SessionBuilder.session(from: routine, ownerID: SampleData.ownerID)
        routine.name = "Renamed"
        routine.exercises[0].exerciseName = "Lunges"
        #expect(session.routineName == "Leg day")
        #expect(session.exercises.first?.exerciseName == "Squats")
    }
}
