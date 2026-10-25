import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct HistoryDetailViewModelTests {
    private let health = FakeHealthService()
    private let sessions = InMemoryWorkoutSessionRepository()
    private let activities = InMemoryActivitySessionRepository()

    private func makeModel(_ entry: HistoryEntry) -> HistoryDetailViewModel {
        HistoryDetailViewModel(
            entry: entry,
            sessions: sessions,
            activities: activities,
            exporter: HealthExporter(health: health, sessions: sessions, activities: activities),
            settings: AppSettings(store: InMemoryPreferencesStore())
        )
    }

    @Test func savingToHealthUpdatesTheStatus() async {
        let model = makeModel(.workout(SampleData.session()))
        #expect(model.canExport)
        model.exportToHealth()
        #expect(await eventually { model.exportStatus == .exported })
        #expect(!model.canExport)
        #expect(model.errorMessage == nil)
    }

    @Test func failedSaveCanBeRetried() async {
        health.saveFailure = CocoaError(.userCancelled)
        let model = makeModel(.activity(SampleData.activity()))
        model.exportToHealth()
        #expect(await eventually { model.exportStatus == .failed && !model.isExporting })
        #expect(model.errorMessage != nil)
        #expect(model.exportTitle == "Try again")
        health.saveFailure = nil
        model.exportToHealth()
        #expect(await eventually { model.exportStatus == .exported })
    }

    @Test func deletingExplainsTheHealthCopyStays() async throws {
        var session = SampleData.session()
        session.healthExport = .exported
        try await sessions.save(session)
        let model = makeModel(.workout(session))
        #expect(model.deleteMessage.contains("Apple Health"))
        model.delete()
        #expect(await eventually { model.isDeleted })
        #expect(await sessions.stored(id: session.id) == nil)
    }

    @Test func noExportWithoutHealth() {
        health.isAvailable = false
        let model = makeModel(.workout(SampleData.session()))
        #expect(!model.canExport)
    }
}
