import Foundation
import Observation

enum ProgressRange: Int, CaseIterable, Identifiable {
    case fourWeeks = 4
    case twelveWeeks = 12
    case twentySixWeeks = 26

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fourWeeks: "Month"
        case .twelveWeeks: "3 months"
        case .twentySixWeeks: "6 months"
        }
    }
}

struct ExerciseChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double

    var id: Date { date }
}

@MainActor
@Observable
final class ProgressHomeViewModel {
    private(set) var sessions: [WorkoutSession] = []
    private(set) var activities: [ActivitySession] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    var range: ProgressRange = .twelveWeeks
    var selectedExerciseID: Int?

    private let repository: any WorkoutSessionRepository
    private let activityRepository: any ActivitySessionRepository
    private let settings: AppSettings

    init(
        repository: any WorkoutSessionRepository,
        activityRepository: any ActivitySessionRepository,
        settings: AppSettings
    ) {
        self.repository = repository
        self.activityRepository = activityRepository
        self.settings = settings
    }

    var hasHistory: Bool {
        !sessions.isEmpty || !activities.isEmpty
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var weeklySummary: WeeklySummary {
        WeeklySummary.make(sessions: sessions, activities: activities, goal: settings.preferences.weeklyGoal)
    }

    var weeklyVolumeText: String {
        let value = Formatting.displayValue(kilograms: weeklySummary.volumeKilograms, units: units)
        return "\(Formatting.number(value)) \(units.symbol)"
    }

    var weeklyStepsText: String {
        "\(Formatting.steps(weeklySummary.steps)) steps"
    }

    var historyGroups: [HistoryGroup] {
        ProgressCalculator.groupByWeek(entries: HistoryEntry.merge(workouts: sessions, activities: activities))
    }

    var weekBuckets: [WeekBucket] {
        ProgressCalculator.weekBuckets(sessions: sessions, activities: activities, weeks: range.rawValue)
    }

    var currentWeekStart: Date? {
        weekBuckets.last?.weekStart
    }

    var totalWorkouts: Int {
        weekBuckets.reduce(0) { $0 + $1.workouts }
    }

    var totalMinutes: Int {
        weekBuckets.reduce(0) { $0 + $1.activeMinutes }
    }

    var subtitle: String {
        let count = sessions.count + activities.count
        switch count {
        case 0: return "Small steps are adding up."
        case 1: return "1 session logged so far."
        default: return "\(count) sessions logged so far."
        }
    }

    var exerciseOptions: [ExerciseOption] {
        ProgressCalculator.exerciseOptions(sessions: sessions)
    }

    var currentExercise: ExerciseOption? {
        exerciseOptions.first { $0.id == selectedExerciseID } ?? exerciseOptions.first
    }

    var currentExerciseID: Int {
        get { currentExercise?.id ?? 0 }
        set { selectedExerciseID = newValue }
    }

    var exerciseProgress: [ExerciseProgressPoint] {
        guard let exercise = currentExercise else {
            return []
        }
        return ProgressCalculator.exerciseProgress(sessions: sessions, exerciseID: exercise.id)
    }

    var exerciseChartUsesLoad: Bool {
        exerciseProgress.contains { $0.bestLoadKilograms > 0 }
    }

    var exerciseChartLabel: String {
        exerciseChartUsesLoad ? "Best load" : "Best reps"
    }

    var exerciseChartPoints: [ExerciseChartPoint] {
        let usesLoad = exerciseChartUsesLoad
        return exerciseProgress.map { point in
            ExerciseChartPoint(
                date: point.date,
                value: usesLoad
                    ? Formatting.displayValue(kilograms: point.bestLoadKilograms, units: units)
                    : Double(point.bestReps)
            )
        }
    }

    var workoutsSummary: String {
        let best = weekBuckets.map(\.workouts).max() ?? 0
        return "\(totalWorkouts) workouts in the last \(range.rawValue) weeks, best week \(best)."
    }

    var minutesSummary: String {
        let best = weekBuckets.map(\.activeMinutes).max() ?? 0
        return "\(totalMinutes) active minutes in the last \(range.rawValue) weeks, best week \(best) minutes."
    }

    var exerciseSummary: String {
        let points = exerciseProgress
        guard let name = currentExercise?.name, let last = points.last else {
            return "No completed sets yet."
        }
        if exerciseChartUsesLoad {
            let best = points.map(\.bestLoadKilograms).max() ?? 0
            let bestText = Formatting.load(.kilograms(best), units: units)
            let lastText = Formatting.load(.kilograms(last.bestLoadKilograms), units: units)
            return "\(name): best load \(bestText) across \(points.count) workouts, latest \(lastText)."
        }
        let best = points.map(\.bestReps).max() ?? 0
        return "\(name): best \(best) reps across \(points.count) workouts, latest \(last.bestReps) reps."
    }

    func load() async {
        do {
            sessions = try await repository.completedSessions(ownerID: settings.ownerID)
            activities = try await activityRepository.completedActivities(ownerID: settings.ownerID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func retry() {
        Task {
            await self.load()
        }
    }
}
