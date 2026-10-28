import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct RoutineEditorViewModelTests {
    private let repository = InMemoryRoutineRepository()

    private func makeModel(routine: Routine? = nil) -> RoutineEditorViewModel {
        RoutineEditorViewModel(
            routine: routine,
            routines: repository,
            settings: AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID)
        )
    }

    @Test func aNewRoutineNeedsAName() {
        let model = makeModel()
        #expect(model.isNew)
        #expect(!model.canSave)
        model.draft.name = "   "
        #expect(!model.canSave)
        model.draft.name = "Push day"
        #expect(model.canSave)
    }

    @Test func changesAreNoticedAndUndone() {
        let routine = SampleData.routine()
        let model = makeModel(routine: routine)
        #expect(!model.hasChanges)
        model.draft.name = "Leg day 2"
        #expect(model.hasChanges)
        model.draft.name = routine.name
        #expect(!model.hasChanges)
    }

    @Test func exercisesCanBeReorderedAndRemoved() {
        let routine = SampleData.routine(exercises: [
            SampleData.routineExercise(id: 1, name: "Squats"),
            SampleData.routineExercise(id: 2, name: "Lunges"),
            SampleData.routineExercise(id: 3, name: "Calf raises"),
        ])
        let model = makeModel(routine: routine)
        model.moveExercises(from: IndexSet(integer: 2), to: 0)
        #expect(model.draft.exercises.map(\.exerciseName) == ["Calf raises", "Squats", "Lunges"])
        model.removeExercises(at: IndexSet(integer: 1))
        #expect(model.draft.exercises.map(\.exerciseName) == ["Calf raises", "Lunges"])
        #expect(model.hasChanges)
    }

    @Test func savingTrimsTheNameAndStoresTheRoutine() async throws {
        let model = makeModel()
        model.draft.name = "  Push day  "
        model.save()
        #expect(await eventually { model.isSaved })
        let saved = try await repository.routine(id: model.draft.id)
        #expect(saved?.name == "Push day")
    }
}
