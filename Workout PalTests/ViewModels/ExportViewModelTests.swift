import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct ExportViewModelTests {
    private func makeModel(sessions: [WorkoutSession] = [], activities: [ActivitySession] = []) -> ExportViewModel {
        ExportViewModel(
            sessions: InMemoryWorkoutSessionRepository(sessions),
            activities: InMemoryActivitySessionRepository(activities),
            settings: AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID),
            now: { SampleData.now }
        )
    }

    @Test func filesAreReadyForEachKindOfHistory() async {
        let model = makeModel(sessions: [SampleData.session()], activities: [SampleData.activity()])
        await model.load()
        #expect(!model.isLoading)
        #expect(model.hasData)
        #expect(model.workoutsSummary == "1 workout, 2 sets")
        #expect(model.activitiesSummary == "1 walk or run")
        #expect(model.workoutsFile?.fileName == "Workout Pal workouts 2026-10-21.csv")
        #expect(model.workoutsFile?.text.hasPrefix("Date,Workout,") == true)
        #expect(model.activitiesFile?.text.hasPrefix("Date,Type,") == true)
    }

    @Test func nothingToExportWithoutHistory() async {
        let model = makeModel()
        await model.load()
        #expect(!model.hasData)
        #expect(model.workoutsFile == nil)
        #expect(model.activitiesFile == nil)
    }

    @Test func activeSessionsAreLeftOut() async {
        let model = makeModel(sessions: [SampleData.session(status: .active)])
        await model.load()
        #expect(model.workoutsFile == nil)
    }
}
