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
    private let account: AccountSession
    private let deviceAuth: any DeviceAuthenticating
    private let health: any HealthService
    private let exporter: HealthExporter
    private let notifications: any NotificationScheduling

    init(inMemory: Bool = false) {
        let stack = CoreDataStack(inMemory: inMemory)
        let catalog = CoreDataExerciseCatalogRepository(stack: stack)
        self.stack = stack
        self.catalog = catalog
        let sessions = CoreDataWorkoutSessionRepository(stack: stack)
        let activities = CoreDataActivitySessionRepository(stack: stack)
        routines = CoreDataRoutineRepository(stack: stack)
        self.sessions = sessions
        self.activities = activities
        catalogSync = ExerciseCatalogSync(client: WgerClient(), catalog: catalog)
        let settings = AppSettings(store: UserDefaultsPreferencesStore())
        self.settings = settings
        permissions = SystemPermissions()
        motion = CoreMotionService()
        deviceAuth = LocalAuthenticator()
        let health = HealthKitService()
        self.health = health
        exporter = HealthExporter(health: health, sessions: sessions, activities: activities)
        let notifications = LocalNotificationScheduler()
        self.notifications = notifications
        account = AccountSession(
            auth: FirebaseAuthService(),
            records: CoreDataAccountDataRepository(stack: stack),
            settings: settings,
            state: UserDefaultsAccountStateStore(),
            notifications: notifications
        )
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(store: stack, settings: settings, account: account, deviceAuth: deviceAuth)
    }

    func makeWelcomeViewModel() -> WelcomeViewModel {
        WelcomeViewModel(account: account)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(sessions: sessions, activities: activities, routines: routines, settings: settings)
    }

    func makeExerciseLibraryViewModel() -> ExerciseLibraryViewModel {
        ExerciseLibraryViewModel(catalog: catalog, sync: catalogSync)
    }

    func makeTrainViewModel() -> TrainViewModel {
        TrainViewModel(repository: routines, settings: settings)
    }

    func makeRoutineDetailViewModel(routineID: UUID) -> RoutineDetailViewModel {
        RoutineDetailViewModel(routineID: routineID, routines: routines, sessions: sessions, settings: settings)
    }

    func makeRoutineEditorViewModel(routine: Routine?) -> RoutineEditorViewModel {
        RoutineEditorViewModel(routine: routine, routines: routines, settings: settings)
    }

    func makeWorkoutSessionViewModel(session: WorkoutSession) -> WorkoutSessionViewModel {
        WorkoutSessionViewModel(
            session: session,
            repository: sessions,
            exporter: exporter,
            notifications: notifications,
            settings: settings
        )
    }

    func makeProgressViewModel() -> ProgressHomeViewModel {
        ProgressHomeViewModel(
            repository: sessions,
            activityRepository: activities,
            health: health,
            permissions: permissions,
            settings: settings
        )
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(settings: settings, deviceAuth: deviceAuth)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(settings: settings, account: account, deviceAuth: deviceAuth)
    }

    func makeHistoryDetailViewModel(entry: HistoryEntry) -> HistoryDetailViewModel {
        HistoryDetailViewModel(
            entry: entry,
            sessions: sessions,
            activities: activities,
            exporter: exporter,
            settings: settings
        )
    }

    func makeRemindersViewModel() -> RemindersViewModel {
        RemindersViewModel(settings: settings, permissions: permissions, notifications: notifications)
    }

    func makeHealthSettingsViewModel() -> HealthSettingsViewModel {
        HealthSettingsViewModel(settings: settings, permissions: permissions, health: health)
    }

    func makePermissionsViewModel() -> PermissionsViewModel {
        PermissionsViewModel(permissions: permissions)
    }

    func makeActivityTrackerViewModel() -> ActivityTrackerViewModel {
        ActivityTrackerViewModel(
            motion: motion,
            permissions: permissions,
            activities: activities,
            exporter: exporter,
            settings: settings
        )
    }

    func makeRepCounterViewModel(
        exercise: CameraExercise? = nil,
        mode: RepCounterMode = .standalone
    ) -> RepCounterViewModel {
        RepCounterViewModel(
            camera: VisionPoseCamera(),
            permissions: permissions,
            sessions: sessions,
            settings: settings,
            exercise: exercise,
            mode: mode
        )
    }
}
