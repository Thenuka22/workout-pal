import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct DashboardViewModelTests {
    private let sessions = InMemoryWorkoutSessionRepository()
    private let activities = InMemoryActivitySessionRepository()

    private func makeModel() -> DashboardViewModel {
        DashboardViewModel(
            sessions: sessions,
            activities: activities,
            routines: InMemoryRoutineRepository(),
            settings: AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID)
        )
    }

    @Test func anUnfinishedWorkoutCanBeDiscarded() async throws {
        let active = SampleData.session(status: .active)
        try await sessions.save(active)
        let model = makeModel()
        await model.load()
        #expect(model.activeSession?.id == active.id)
        model.discardActiveSession()
        #expect(await eventually { model.activeSession == nil })
        #expect(await sessions.stored(id: active.id) == nil)
    }

    @Test func anUnfinishedWalkCanBeDiscarded() async throws {
        var walk = SampleData.activity()
        walk.status = .active
        walk.endedAt = nil
        try await activities.save(walk)
        let model = makeModel()
        await model.load()
        #expect(model.activeActivity?.id == walk.id)
        model.discardActiveActivity()
        #expect(await eventually { model.activeActivity == nil })
        #expect(await activities.stored(id: walk.id) == nil)
    }

    @Test func theLatestWorkoutIsShownAsRecent() async throws {
        try await sessions.save(SampleData.session(startedAt: SampleData.daysAgo(3), name: "Older"))
        try await sessions.save(SampleData.session(startedAt: SampleData.daysAgo(1), name: "Newer"))
        let model = makeModel()
        await model.load()
        #expect(model.recentSession?.routineName == "Newer")
    }
}
