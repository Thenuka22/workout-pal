import Foundation
import Testing
@testable import Workout_Pal

struct HealthExporterTests {
    private let health = FakeHealthService()
    private let sessions = InMemoryWorkoutSessionRepository()
    private let activities = InMemoryActivitySessionRepository()

    private var exporter: HealthExporter {
        HealthExporter(health: health, sessions: sessions, activities: activities)
    }

    @Test func exportedWorkoutIsMarkedAsSaved() async throws {
        let session = SampleData.session(minutes: 45)
        try await sessions.save(session)
        let status = await exporter.export(.workout(session))
        #expect(status == .exported)
        #expect(await sessions.stored(id: session.id)?.healthExport == .exported)
        #expect(health.savedWorkouts[session.id]?.kind == .strength)
    }

    @Test func retryingDoesNotCreateASecondWorkout() async throws {
        let walk = SampleData.activity()
        try await activities.save(walk)
        _ = await exporter.export(.activity(walk))
        _ = await exporter.export(.activity(walk))
        #expect(health.saveAttempts == 2)
        #expect(health.savedWorkouts.count == 1)
        #expect(health.savedWorkouts[walk.id]?.kind == .walk)
    }

    @Test func failedExportKeepsTheLocalWorkout() async throws {
        health.saveFailure = CocoaError(.userCancelled)
        let session = SampleData.session()
        try await sessions.save(session)
        let status = await exporter.export(.workout(session))
        #expect(status == .failed)
        let stored = await sessions.stored(id: session.id)
        #expect(stored?.healthExport == .failed)
        #expect(stored?.completedSetCount == session.completedSetCount)
    }

    @Test func unfinishedWorkoutsAreNotExported() async {
        let active = SampleData.session(status: .active)
        let status = await exporter.export(.workout(active))
        #expect(status == .notExported)
        #expect(health.saveAttempts == 0)
    }

    @Test func noHealthAppMeansTheExportFails() async {
        health.isAvailable = false
        let status = await exporter.export(.workout(SampleData.session()))
        #expect(status == .failed)
        #expect(health.saveAttempts == 0)
    }

    @Test func exportKeepsOnlyTheActiveTime() throws {
        var run = SampleData.activity(kind: .run, minutes: 30)
        run.pauses = [
            PauseInterval(start: run.startedAt.addingTimeInterval(600), end: run.startedAt.addingTimeInterval(900)),
            PauseInterval(start: run.startedAt.addingTimeInterval(-60), end: run.startedAt.addingTimeInterval(60)),
        ]
        let workout = try #require(HealthWorkoutExport(activity: run))
        #expect(workout.kind == .run)
        #expect(workout.pauses.count == 2)
        #expect(workout.activeSeconds == 1_800 - 300 - 60)
    }
}
