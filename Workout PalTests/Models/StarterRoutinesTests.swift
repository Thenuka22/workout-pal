import Foundation
import Testing
@testable import Workout_Pal

struct StarterRoutinesTests {
    private let catalog = [
        SampleData.catalogExercise(id: 1, name: "Squats", category: "Legs"),
        SampleData.catalogExercise(id: 2, name: "Wall Sit", category: "Legs"),
        SampleData.catalogExercise(id: 3, name: "Push-Ups", category: "Chest", equipment: ["none (bodyweight exercise)"]),
        SampleData.catalogExercise(id: 4, name: "Superman", category: "Back", equipment: ["Gym mat"]),
        SampleData.catalogExercise(id: 5, name: "Crunches", category: "Abs", equipment: ["Gym mat"]),
        SampleData.catalogExercise(id: 6, name: "Lateral Raises", category: "Shoulders", equipment: ["Dumbbell"]),
        SampleData.catalogExercise(id: 7, name: "Deadlifts", category: "Back", equipment: ["Barbell"]),
        SampleData.catalogExercise(id: 8, name: "Bench Press", category: "Chest", equipment: ["Barbell", "Bench"]),
    ]

    @Test func beginnerPlanUsesThePreferredExercises() throws {
        let routines = StarterRoutines.routines(for: .beginner, catalog: catalog, ownerID: "owner", now: SampleData.now)
        let routine = try #require(routines.first)
        #expect(routines.count == 1)
        #expect(routine.name == "Full body foundations")
        #expect(routine.ownerID == "owner")
        #expect(routine.exercises.map(\.exerciseName) == ["Squats", "Push-Ups", "Superman", "Crunches", "Lateral Raises"])
        #expect(routine.exercises.first?.plannedLoad == .bodyweight)
        #expect(routine.exercises.last?.plannedLoad == .kilograms(20))
    }

    @Test func missingNamesFallBackToTheSameBodyArea() {
        let slot = StarterSlot(area: .legs, difficulty: .beginner, preferredNames: ["Not In Catalog"], sets: 3, reps: 10, restSeconds: 60)
        let items = CatalogGrouping.items(from: catalog)
        #expect(StarterRoutines.pick(slot, from: items, excluding: [])?.exercise.name == "Squats")
        #expect(StarterRoutines.pick(slot, from: items, excluding: [1])?.exercise.name == "Wall Sit")
    }

    @Test func exercisesAreNotRepeatedInARoutine() {
        let routines = StarterRoutines.routines(for: .advanced, catalog: catalog, ownerID: "owner")
        #expect(routines.count == 3)
        for routine in routines {
            let ids = routine.exercises.map(\.exerciseID)
            #expect(Set(ids).count == ids.count)
        }
    }

    @Test func emptyCatalogueBuildsNothing() {
        #expect(StarterRoutines.routines(for: .intermediate, catalog: [], ownerID: "owner").isEmpty)
    }

    @Test func everyLevelHasAPlan() {
        for level in FitnessLevel.allCases {
            #expect(!StarterRoutines.templates(for: level).isEmpty)
            #expect(!StarterRoutines.summary(for: level).isEmpty)
        }
    }
}

@MainActor
struct TrainViewModelTests {
    private let routines = InMemoryRoutineRepository()

    private func makeModel(catalog: [Exercise], downloadable: [Exercise] = []) -> TrainViewModel {
        let repository = InMemoryExerciseCatalogRepository(catalog)
        return TrainViewModel(
            repository: routines,
            catalog: repository,
            sync: SeedingCatalogSync(catalog: repository, exercises: downloadable),
            settings: AppSettings(store: InMemoryPreferencesStore())
        )
    }

    @Test func addingAStarterPlanSavesItsRoutines() async {
        let model = makeModel(catalog: [
            SampleData.catalogExercise(id: 1, name: "Squats", category: "Legs"),
            SampleData.catalogExercise(id: 3, name: "Push-Ups", category: "Chest"),
        ])
        await model.load()
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { !model.isAddingStarter && model.routines.count == 1 })
        #expect(model.routines.first?.name == "Full body foundations")
        #expect(model.starterMessage?.hasPrefix("Added") == true)
    }

    @Test func addingTwiceDoesNotDuplicate() async {
        let model = makeModel(catalog: [SampleData.catalogExercise(id: 1, name: "Squats", category: "Legs")])
        await model.load()
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { !model.isAddingStarter && model.routines.count == 1 })
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { !model.isAddingStarter && model.starterMessage == "These routines are already in your list." })
        #expect(model.routines.count == 1)
    }

    @Test func emptyLibraryAsksForADownload() async {
        let model = makeModel(catalog: [])
        model.addStarterRoutines(level: .advanced)
        #expect(await eventually { !model.isAddingStarter && model.starterMessage != nil })
        #expect(model.starterMessage?.contains("Download") == true)
        #expect(model.pendingStarterLevel == .advanced)
        #expect(model.routines.isEmpty)
    }

    @Test func downloadingTheLibraryThenAddsThePlan() async {
        let model = makeModel(catalog: [], downloadable: [
            SampleData.catalogExercise(id: 1, name: "Squats", category: "Legs"),
            SampleData.catalogExercise(id: 3, name: "Push-Ups", category: "Chest"),
        ])
        await model.load()
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { model.pendingStarterLevel == .beginner && !model.isAddingStarter })
        model.downloadLibraryForStarter()
        #expect(await eventually { !model.isAddingStarter && model.routines.count == 1 })
        #expect(model.pendingStarterLevel == nil)
        #expect(model.starterMessage?.hasPrefix("Added") == true)
    }

    @Test func deletingARoutineNeedsConfirmation() async {
        let model = makeModel(catalog: [SampleData.catalogExercise(id: 1, name: "Squats", category: "Legs")])
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { !model.isAddingStarter && model.routines.count == 1 })
        model.requestDelete(at: IndexSet(integer: 0))
        #expect(model.isConfirmingDelete)
        #expect(model.deleteTitle == "Delete Full body foundations?")
        #expect(model.routines.count == 1)
        model.confirmDelete()
        #expect(await eventually { model.routines.isEmpty })
    }

    @Test func declinedDownloadAddsNothing() async {
        let model = makeModel(catalog: [])
        model.addStarterRoutines(level: .beginner)
        #expect(await eventually { model.pendingStarterLevel != nil && !model.isAddingStarter })
        model.cancelStarterDownload()
        model.downloadLibraryForStarter()
        #expect(model.pendingStarterLevel == nil)
        #expect(!model.isAddingStarter)
    }
}
