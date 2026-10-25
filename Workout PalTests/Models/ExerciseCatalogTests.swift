import Foundation
import Testing
@testable import Workout_Pal

struct ExerciseCatalogTests {
    private let catalog = [
        SampleData.catalogExercise(id: 1, name: "Crunches", category: "Abs", equipment: ["Gym mat"]),
        SampleData.catalogExercise(id: 2, name: "Dips", category: "Chest", equipment: ["none (bodyweight exercise)"]),
        SampleData.catalogExercise(id: 3, name: "Deadlifts", category: "Back", equipment: ["Barbell"]),
        SampleData.catalogExercise(id: 4, name: "Benchpress Dumbbells", category: "Chest", equipment: ["Bench", "Dumbbell"]),
        SampleData.catalogExercise(id: 5, name: "Seated Hip Adduction", category: "Legs"),
        SampleData.catalogExercise(id: 6, name: "Biceps Curls With Dumbbell", category: "Arms", equipment: ["Dumbbell"], muscles: ["Biceps brachii"]),
        SampleData.catalogExercise(id: 7, name: "Pistol Squat", category: "Legs"),
        SampleData.catalogExercise(id: 8, name: "Squats", category: "Legs"),
    ]

    private var items: [CatalogItem] {
        CatalogGrouping.items(from: catalog)
    }

    private func level(_ name: String) -> ExerciseDifficulty? {
        items.first { $0.exercise.name == name }?.difficulty
    }

    @Test func levelsAreEstimatedFromNameAndEquipment() {
        #expect(level("Crunches") == .beginner)
        #expect(level("Dips") == .intermediate)
        #expect(level("Deadlifts") == .advanced)
        #expect(level("Benchpress Dumbbells") == .intermediate)
        #expect(level("Seated Hip Adduction") == .beginner)
        #expect(level("Pistol Squat") == .advanced)
        #expect(level("Squats") == .beginner)
    }

    @Test func wgerCategoriesMapToBodyAreas() {
        #expect(BodyArea(category: "Abs") == .abs)
        #expect(BodyArea(category: " shoulders ") == .shoulders)
        #expect(BodyArea(category: "Mobility") == .other)
        #expect(BodyArea(category: "") == .other)
    }

    @Test func allShowsEverySectionInBodyAreaOrder() {
        let sections = CatalogGrouping.sections(items: items, scope: .all, difficulty: nil, query: "", fitnessLevel: nil)
        #expect(sections.map(\.area) == [.abs, .arms, .back, .chest, .legs])
        #expect(sections.flatMap(\.items).count == catalog.count)
    }

    @Test func sectionsListEasiestFirst() {
        let sections = CatalogGrouping.sections(items: items, scope: .area(.legs), difficulty: nil, query: "", fitnessLevel: nil)
        #expect(sections.count == 1)
        #expect(sections.first?.items.map(\.exercise.name) == ["Seated Hip Adduction", "Squats", "Pistol Squat"])
    }

    @Test func forYouMatchesTheFitnessLevel() {
        let beginner = CatalogGrouping.sections(items: items, scope: .forYou, difficulty: nil, query: "", fitnessLevel: .beginner)
        #expect(beginner.flatMap(\.items).allSatisfy { $0.difficulty == .beginner })
        let intermediate = CatalogGrouping.sections(items: items, scope: .forYou, difficulty: nil, query: "", fitnessLevel: .intermediate)
        #expect(!intermediate.flatMap(\.items).contains { $0.difficulty == .advanced })
        let advanced = CatalogGrouping.sections(items: items, scope: .forYou, difficulty: nil, query: "", fitnessLevel: .advanced)
        #expect(advanced.flatMap(\.items).count == catalog.count)
    }

    @Test func choosingALevelOverridesForYou() {
        let sections = CatalogGrouping.sections(items: items, scope: .forYou, difficulty: .advanced, query: "", fitnessLevel: .beginner)
        #expect(sections.flatMap(\.items).map(\.exercise.name).sorted() == ["Deadlifts", "Pistol Squat"])
    }

    @Test func searchWorksAcrossSections() {
        let sections = CatalogGrouping.sections(items: items, scope: .all, difficulty: nil, query: "  biceps ", fitnessLevel: nil)
        #expect(sections.map(\.area) == [.arms])
        let none = CatalogGrouping.sections(items: items, scope: .all, difficulty: nil, query: "zzz", fitnessLevel: nil)
        #expect(none.isEmpty)
    }

    @Test func scopesOnlyListAreasThatHaveExercises() {
        let scopes = CatalogGrouping.scopes(for: items)
        #expect(scopes.first == .forYou)
        #expect(scopes.contains(.area(.legs)))
        #expect(!scopes.contains(.area(.calves)))
    }

    @Test func bodyweightExercisesSuggestNoLoad() {
        #expect(catalog[0].suggestedLoad == .bodyweight)
        #expect(catalog[3].suggestedLoad == .kilograms(20))
        #expect(catalog[4].suggestedLoad == .bodyweight)
    }
}

@MainActor
struct ExerciseLibraryViewModelTests {
    private func makeModel(level: FitnessLevel?) -> ExerciseLibraryViewModel {
        var preferences = UserPreferences.standard
        preferences.fitnessLevel = level
        let catalog = InMemoryExerciseCatalogRepository([
            SampleData.catalogExercise(id: 1, name: "Crunches", category: "Abs", equipment: ["Gym mat"]),
            SampleData.catalogExercise(id: 3, name: "Deadlifts", category: "Back", equipment: ["Barbell"]),
        ])
        return ExerciseLibraryViewModel(
            catalog: catalog,
            sync: FakeCatalogSync(),
            settings: AppSettings(store: InMemoryPreferencesStore(preferences))
        )
    }

    @Test func profileLevelStartsOnForYou() async {
        let model = makeModel(level: .beginner)
        #expect(model.scope == .forYou)
        await model.load()
        #expect(model.sections.map(\.area) == [.abs])
        #expect(model.scopeCaption != nil)
    }

    @Test func withoutALevelEverythingIsShown() async {
        let model = makeModel(level: nil)
        #expect(model.scope == .all)
        await model.load()
        #expect(model.filteredExercises.count == 2)
        model.scope = .area(.back)
        #expect(model.filteredExercises.map(\.name) == ["Deadlifts"])
    }
}
