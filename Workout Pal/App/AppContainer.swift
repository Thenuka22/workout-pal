import Observation

@MainActor
@Observable
final class AppContainer {
    private let stack: CoreDataStack
    private let routines: any RoutineRepository
    private let sessions: any WorkoutSessionRepository
    private let catalog: any ExerciseCatalogRepository
    private let catalogSync: any ExerciseCatalogSyncing
    private let settings: AppSettings

    init(inMemory: Bool = false) {
        let stack = CoreDataStack(inMemory: inMemory)
        let catalog = CoreDataExerciseCatalogRepository(stack: stack)
        self.stack = stack
        self.catalog = catalog
        routines = CoreDataRoutineRepository(stack: stack)
        sessions = CoreDataWorkoutSessionRepository(stack: stack)
        catalogSync = ExerciseCatalogSync(client: WgerClient(), catalog: catalog)
        settings = AppSettings(store: UserDefaultsPreferencesStore())
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(store: stack)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(sessions: sessions, settings: settings)
    }
}
