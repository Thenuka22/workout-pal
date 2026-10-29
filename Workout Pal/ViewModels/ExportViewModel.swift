import Foundation
import Observation

@MainActor
@Observable
final class ExportViewModel {
    private(set) var workoutsFile: CSVFile?
    private(set) var activitiesFile: CSVFile?
    private(set) var workoutCount = 0
    private(set) var setCount = 0
    private(set) var activityCount = 0
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let sessions: any WorkoutSessionRepository
    private let activities: any ActivitySessionRepository
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    private let timeZone: TimeZone

    init(
        sessions: any WorkoutSessionRepository,
        activities: any ActivitySessionRepository,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now },
        timeZone: TimeZone = .current
    ) {
        self.sessions = sessions
        self.activities = activities
        self.settings = settings
        self.now = now
        self.timeZone = timeZone
    }

    var hasData: Bool {
        workoutsFile != nil || activitiesFile != nil
    }

    var workoutsSummary: String {
        "\(Formatting.count(workoutCount, "workout")), \(Formatting.count(setCount, "set"))"
    }

    var activitiesSummary: String {
        Formatting.count(activityCount, "walk or run", plural: "walks and runs")
    }

    func load() async {
        do {
            let workouts = try await sessions.completedSessions(ownerID: settings.ownerID)
            let walks = try await activities.completedActivities(ownerID: settings.ownerID)
            let units = settings.preferences.units
            let day = now().formatted(Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day())
            workoutCount = workouts.count
            setCount = workouts.reduce(0) { $0 + $1.completedSetCount }
            activityCount = walks.count
            workoutsFile = workouts.isEmpty
                ? nil
                : CSVFile(fileName: "Workout Pal workouts \(day).csv", text: WorkoutCSV.sets(sessions: workouts, units: units, timeZone: timeZone))
            activitiesFile = walks.isEmpty
                ? nil
                : CSVFile(fileName: "Workout Pal walks and runs \(day).csv", text: WorkoutCSV.activities(walks, units: units, timeZone: timeZone))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
