import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct AddToRoutineViewModelTests {
    private let settings = AppSettings(store: InMemoryPreferencesStore(), ownerID: SampleData.ownerID)
    private let squat = SampleData.catalogExercise(id: 42, name: "Squats")
    private let press = SampleData.catalogExercise(id: 7, name: "Bench press", equipment: ["Barbell"])

    private func makeModel(_ exercise: Exercise, routines: [Routine] = []) -> (AddToRoutineViewModel, InMemoryRoutineRepository) {
        let repository = InMemoryRoutineRepository(routines)
        let model = AddToRoutineViewModel(exercise: exercise, repository: repository, settings: settings, now: { SampleData.now })
        return (model, repository)
    }

    @Test func listsThisAccountsRoutines() async {
        let mine = SampleData.routine(name: "Leg day")
        let theirs = SampleData.routine(name: "Not mine", ownerID: "someone-else")
        let (model, _) = makeModel(squat, routines: [mine, theirs])
        await model.load()
        #expect(!model.isLoading)
        #expect(model.routines.map(\.name) == ["Leg day"])
    }

    @Test func addingAppendsAPlannedExercise() async throws {
        let routine = SampleData.routine(name: "Push", exercises: [])
        let (model, repository) = makeModel(press, routines: [routine])
        await model.load()
        model.add(to: routine)
        #expect(await eventually { model.savedMessage == "Added to Push." })
        let stored = try #require(try await repository.routine(id: routine.id))
        #expect(stored.exercises.map(\.exerciseID) == [7])
        #expect(stored.exercises.first?.plannedSets == 3)
        #expect(stored.exercises.first?.plannedLoad == press.suggestedLoad)
        #expect(model.contains(model.routines[0]))
    }

    @Test func exercisesAreNotAddedTwice() async throws {
        let routine = SampleData.routine(name: "Leg day", exercises: [SampleData.routineExercise(id: 42, name: "Squats")])
        let (model, repository) = makeModel(squat, routines: [routine])
        await model.load()
        model.add(to: routine)
        #expect(model.savedMessage == "Squats is already in Leg day.")
        let stored = try #require(try await repository.routine(id: routine.id))
        #expect(stored.exercises.count == 1)
    }

    @Test func aNewRoutineStartsWithTheExercise() async throws {
        let (model, repository) = makeModel(squat)
        await model.load()
        #expect(!model.canCreateRoutine)
        model.newRoutineName = "  Morning legs "
        #expect(model.canCreateRoutine)
        model.createRoutine()
        #expect(await eventually { !model.routines.isEmpty })
        let stored = try await repository.routines(ownerID: SampleData.ownerID)
        #expect(stored.map(\.name) == ["Morning legs"])
        #expect(stored.first?.exercises.map(\.exerciseName) == ["Squats"])
        #expect(model.newRoutineName.isEmpty)
    }
}
