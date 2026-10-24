import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    private let stack: CoreDataStack
    private let routines: any RoutineRepository
    private let sessions: any WorkoutSessionRepository
    private let activities: any ActivitySessionRepository
    private let catalog: any ExerciseCatalogRepository
    private let catalogSync: any ExerciseCatalogSyncing
    private let settings: AppSettings
    private let permissions: any PermissionsProviding
    private let motion: any MotionTracking

    init(inMemory: Bool = false) {
        let stack = CoreDataStack(inMemory: inMemory)
        let catalog = CoreDataExerciseCatalogRepository(stack: stack)
        self.stack = stack
        self.catalog = catalog
        routines = CoreDataRoutineRepository(stack: stack)
        sessions = CoreDataWorkoutSessionRepository(stack: stack)
        activities = CoreDataActivitySessionRepository(stack: stack)
        catalogSync = ExerciseCatalogSync(client: WgerClient(), catalog: catalog)
        settings = AppSettings(store: UserDefaultsPreferencesStore())
        permissions = SystemPermissions()
        motion = CoreMotionService()
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(store: stack, settings: settings)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(sessions: sessions, activities: activities, routines: routines, settings: settings)
    }

    func makeExerciseLibraryViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel(catalog: catalog, sync: catalogSync)
    }

    func makeTrainViewModel() -> TrainViewModel {
        TrainViewModel(repository: routines)
    }

    func makeRoutineDetailViewModel(routineID: UUID) -> RoutineDetailViewModel {
        RoutineDetailViewModel(routineID: routineID, routines: routines, sessions: sessions, settings: settings)
    }

    func makeRoutineEditorViewModel(routine: Routine?) -> RoutineEditorViewModel {
        RoutineEditorViewModel(routine: routine, routines: routines, settings: settings)
    }

    func makeWorkoutSessionViewModel(session: WorkoutSession) -> WorkoutSessionViewModel {
        WorkoutSessionViewModel(session: session, repository: sessions, settings: settings)
    }

    func makeProgressViewModel() -> ProgressHomeViewModel {
        ProgressHomeViewModel(repository: sessions, activityRepository: activities, settings: settings)
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(settings: settings)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(settings: settings)
    }

    func makePermissionsViewModel() -> PermissionsViewModel {
        PermissionsViewModel(permissions: permissions)
    }

    func makeActivityTrackerViewModel() -> ActivityTrackerViewModel {
        ActivityTrackerViewModel(motion: motion, permissions: permissions, activities: activities, settings: settings)
    }

    func makeRepCounterViewModel(
        exercise: CameraExercise? = nil,
        mode: RepCounterMode = .standalone
    ) -> RepCounterViewModel {
        RepCounterViewModel(
            camera: VisionPoseCamera(),
            permissions: permissions,
            sessions: sessions,
            exercise: exercise,
            mode: mode
        )
    }
}
