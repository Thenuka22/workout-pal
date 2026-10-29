import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct ExerciseHistoryViewModelTests {
    private func makeModel(_ sessions: [WorkoutSession]) -> ExerciseHistoryViewModel {
        ExerciseHistoryViewModel(
            exerciseID: 1,
            exerciseName: "Squats",
            repository: InMemoryWorkoutSessionRepository(sessions),
            settings: AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID)
        )
    }

    @Test func bestsAreDescribedInTheChosenUnits() async {
        let model = makeModel([
            SampleData.session(
                startedAt: SampleData.daysAgo(4),
                exercises: [SampleData.exercise(sets: [SampleData.set(reps: 3, load: .kilograms(100))])]
            ),
            SampleData.session(
                startedAt: SampleData.daysAgo(1),
                exercises: [SampleData.exercise(sets: [SampleData.set(reps: 10, load: .kilograms(90))])]
            ),
        ])
        await model.load()
        #expect(model.hasHistory)
        #expect(model.countText == "Logged in 2 workouts")
        #expect(model.bestSetText == "100 kg × 3")
        #expect(model.oneRepMaxText == "120 kg")
        #expect(model.chartLabel == "Best load (kg)")
        #expect(model.chartPoints.map(\.value) == [100, 90])
        #expect(model.setsText(model.recentEntries[0]) == "1 × 10 · 90 kg")
    }

    @Test func onlyTheThreeLatestWorkoutsAreShownOnTheCard() async {
        let sessions = (1...5).map { SampleData.session(startedAt: SampleData.daysAgo($0)) }
        let model = makeModel(sessions)
        await model.load()
        #expect(model.recentEntries.count == 3)
        #expect(model.history.entries.count == 5)
    }

    @Test func anExerciseNeverLoggedSaysSo() async {
        let model = makeModel([])
        await model.load()
        #expect(!model.hasHistory)
        #expect(!model.isLoading)
        #expect(model.bestSetText == nil)
        #expect(model.emptyText.contains("Squats"))
    }
}
