import Foundation
import Testing
@testable import Workout_Pal

struct CoreDataRepositoryTests {
    private func makeStack() async throws -> CoreDataStack {
        let stack = CoreDataStack(inMemory: true)
        try await stack.load()
        return stack
    }

    @Test func routineKeepsItsExerciseOrder() async throws {
        let repository = CoreDataRoutineRepository(stack: try await makeStack())
        let routine = SampleData.routine(exercises: [
            SampleData.routineExercise(id: 3, name: "Squats"),
            SampleData.routineExercise(id: 1, name: "Bench press", load: .kilograms(60)),
            SampleData.routineExercise(id: 2, name: "Rows"),
        ])
        try await repository.save(routine)
        let loaded = try #require(try await repository.routine(id: routine.id))
        #expect(loaded.exercises.map(\.exerciseName) == ["Squats", "Bench press", "Rows"])
        #expect(loaded.exercises[1].plannedLoad == .kilograms(60))
        #expect(loaded.exercises[0].plannedLoad == .bodyweight)
    }

    @Test func routinesBelongToTheirOwner() async throws {
        let repository = CoreDataRoutineRepository(stack: try await makeStack())
        try await repository.save(SampleData.routine(name: "Mine", ownerID: "owner-a"))
        try await repository.save(SampleData.routine(name: "Theirs", ownerID: "owner-b"))
        let mine = try await repository.routines(ownerID: "owner-a")
        #expect(mine.map(\.name) == ["Mine"])
    }

    @Test func completedWorkoutKeepsItsSnapshotAfterTheRoutineChanges() async throws {
        let stack = try await makeStack()
        let routines = CoreDataRoutineRepository(stack: stack)
        let sessions = CoreDataWorkoutSessionRepository(stack: stack)
        var routine = SampleData.routine()
        try await routines.save(routine)
        var session = SessionBuilder.session(from: routine, ownerID: SampleData.ownerID)
        session.status = .completed
        try await sessions.save(session)

        routine.name = "Renamed"
        routine.exercises = [SampleData.routineExercise(id: 9, name: "Lunges")]
        try await routines.save(routine)

        let loaded = try #require(try await sessions.session(id: session.id))
        #expect(loaded.routineName == "Leg day")
        #expect(loaded.exercises.map(\.exerciseName) == ["Squats"])
    }

    @Test func workoutRoundTripsPausesSetsAndExportStatus() async throws {
        let repository = CoreDataWorkoutSessionRepository(stack: try await makeStack())
        var session = SampleData.session(exercises: [
            SampleData.exercise(sets: [SampleData.set(reps: 12, source: .camera), SampleData.set(isCompleted: false)]),
        ])
        session.pauses = [PauseInterval(start: SampleData.now, end: SampleData.now.addingTimeInterval(30))]
        session.healthExport = .failed
        try await repository.save(session)
        let loaded = try #require(try await repository.session(id: session.id))
        #expect(loaded.pauses == session.pauses)
        #expect(loaded.healthExport == .failed)
        #expect(loaded.exercises.first?.sets.map(\.reps) == [12, 10])
        #expect(loaded.exercises.first?.sets.first?.source == .camera)
    }

    @Test func activeAndCompletedWorkoutsAreKeptApart() async throws {
        let repository = CoreDataWorkoutSessionRepository(stack: try await makeStack())
        let active = SampleData.session(status: .active)
        let completed = SampleData.session()
        try await repository.save(active)
        try await repository.save(completed)
        #expect(try await repository.activeSession(ownerID: SampleData.ownerID)?.id == active.id)
        #expect(try await repository.completedSessions(ownerID: SampleData.ownerID).map(\.id) == [completed.id])
        #expect(try await repository.completedSessions(ownerID: "someone-else").isEmpty)
    }

    @Test func updatingTheExportStatusKeepsTheSets() async throws {
        let repository = CoreDataWorkoutSessionRepository(stack: try await makeStack())
        let session = SampleData.session()
        try await repository.save(session)
        try await repository.updateHealthExport(id: session.id, status: .exported)
        let loaded = try #require(try await repository.session(id: session.id))
        #expect(loaded.healthExport == .exported)
        #expect(loaded.totalSetCount == session.totalSetCount)
    }

    @Test func activityRoundTripsMissingDistance() async throws {
        let repository = CoreDataActivitySessionRepository(stack: try await makeStack())
        let withDistance = SampleData.activity(distanceMeters: 1_250)
        let withoutDistance = SampleData.activity(kind: .run, startedAt: SampleData.daysAgo(1), distanceMeters: nil)
        try await repository.save(withDistance)
        try await repository.save(withoutDistance)
        let loaded = try await repository.completedActivities(ownerID: SampleData.ownerID)
        #expect(loaded.map(\.id) == [withDistance.id, withoutDistance.id])
        #expect(loaded[0].distanceMeters == 1_250)
        #expect(loaded[1].distanceMeters == nil)
        #expect(loaded[1].kind == .run)
        #expect(loaded[0].detectedMotion == .walking)
    }

    @Test func deletingAnActivityRemovesIt() async throws {
        let repository = CoreDataActivitySessionRepository(stack: try await makeStack())
        let activity = SampleData.activity()
        try await repository.save(activity)
        try await repository.deleteActivity(id: activity.id)
        #expect(try await repository.completedActivities(ownerID: SampleData.ownerID).isEmpty)
    }

    @Test func signingInMovesLocalRecordsToTheAccount() async throws {
        let stack = try await makeStack()
        let routines = CoreDataRoutineRepository(stack: stack)
        let sessions = CoreDataWorkoutSessionRepository(stack: stack)
        let activities = CoreDataActivitySessionRepository(stack: stack)
        try await routines.save(SampleData.routine(ownerID: LocalProfile.ownerID))
        try await sessions.save(SampleData.session(ownerID: LocalProfile.ownerID))
        try await activities.save(SampleData.activity(ownerID: LocalProfile.ownerID))
        try await routines.save(SampleData.routine(name: "Other", ownerID: "someone-else"))

        try await CoreDataAccountDataRepository(stack: stack).reassignRecords(from: LocalProfile.ownerID, to: "uid")

        #expect(try await routines.routines(ownerID: "uid").count == 1)
        #expect(try await routines.routines(ownerID: LocalProfile.ownerID).isEmpty)
        #expect(try await sessions.completedSessions(ownerID: "uid").count == 1)
        #expect(try await activities.completedActivities(ownerID: "uid").count == 1)
        #expect(try await routines.routines(ownerID: "someone-else").count == 1)
    }

    @Test func deletingAnAccountsRecordsKeepsOtherAccounts() async throws {
        let stack = try await makeStack()
        let routines = CoreDataRoutineRepository(stack: stack)
        let sessions = CoreDataWorkoutSessionRepository(stack: stack)
        try await routines.save(SampleData.routine(ownerID: "uid"))
        try await sessions.save(SampleData.session(ownerID: "uid"))
        try await routines.save(SampleData.routine(name: "Keep", ownerID: "other"))

        try await CoreDataAccountDataRepository(stack: stack).deleteRecords(ownerID: "uid")

        #expect(try await routines.routines(ownerID: "uid").isEmpty)
        #expect(try await sessions.completedSessions(ownerID: "uid").isEmpty)
        #expect(try await routines.routines(ownerID: "other").map(\.name) == ["Keep"])
    }
}
