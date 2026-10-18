import Observation

@MainActor
@Observable
final class AppContainer {
    private let stack: CoreDataStack
    private let routines: any RoutineRepository
    private let sessions: any WorkoutSessionRepository
    private let catalog: any ExerciseCatalogRepository
    private let settings: AppSettings

    init(inMemory: Bool = false) {
        let stack = CoreDataStack(inMemory: inMemory)
        self.stack = stack
        routines = CoreDataRoutineRepository(stack: stack)
        sessions = CoreDataWorkoutSessionRepository(stack: stack)
        catalog = CoreDataExerciseCatalogRepository(stack: stack)
        settings = AppSettings(store: UserDefaultsPreferencesStore())
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(store: stack)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(sessions: sessions, settings: settings)
    }
}
