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
    private(set) var healthState: HealthCardState = .loading
    var range: ProgressRange = .twelveWeeks
    var selectedExerciseID: Int?

    private let repository: any WorkoutSessionRepository
    private let activityRepository: any ActivitySessionRepository
    private let health: any HealthService
    private let permissions: any PermissionsProviding
    private let settings: AppSettings
    private let now: @MainActor () -> Date

    init(
        repository: any WorkoutSessionRepository,
        activityRepository: any ActivitySessionRepository,
        health: any HealthService,
        permissions: any PermissionsProviding,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.repository = repository
        self.activityRepository = activityRepository
        self.health = health
        self.permissions = permissions
        self.settings = settings
        self.now = now
    }

    var todayActiveMinutes: Int {
        let calendar = Calendar.current
        let today = now()
        let workoutSeconds = sessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: today) }
            .reduce(0.0) { $0 + $1.activeSeconds }
        let activitySeconds = activities
            .filter { calendar.isDate($0.startedAt, inSameDayAs: today) }
            .reduce(0.0) { $0 + $1.activeSeconds }
        return Int(((workoutSeconds + activitySeconds) / 60).rounded())
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

    var allRecords: [PersonalRecord] {
        RecordBook.bests(sessions: sessions)
    }

    var records: [PersonalRecord] {
        Array(allRecords.prefix(5))
    }

    var weekStreak: Int {
        StreakCalculator.weekStreak(sessions: sessions, goal: settings.preferences.weeklyGoal, now: now())
    }

    var streakText: String {
        weekStreak == 1 ? "1 week" : "\(weekStreak) weeks"
    }

    func recordText(_ record: PersonalRecord) -> String {
        Formatting.record(record, units: units)
    }

    var weeklyStepsText: String {
        "\(Formatting.steps(weeklySummary.steps)) steps"
    }

    var historyGroups: [HistoryGroup] {
        ProgressCalculator.groupByWeek(entries: HistoryEntry.merge(workouts: sessions, activities: activities))
    }

    var weekBuckets: [WeekBucket] {
        ProgressCalculator.weekBuckets(sessions: sessions, activities: activities, weeks: range.rawValue, now: now())
    }

    var sessionsInRange: [WorkoutSession] {
        guard let start = weekBuckets.first?.weekStart else {
            return sessions
        }
        return sessions.filter { $0.startedAt >= start }
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
        return ProgressCalculator.exerciseProgress(sessions: sessionsInRange, exerciseID: exercise.id)
    }

    var exerciseChartUsesLoad: Bool {
        exerciseProgress.contains { $0.bestLoadKilograms > 0 }
    }

    var exerciseChartLabel: String {
        exerciseChartUsesLoad ? "Best load (\(units.symbol))" : "Best reps"
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
        return "\(Formatting.count(totalWorkouts, "workout")) in the last \(range.rawValue) weeks, best week \(best)."
    }

    var minutesSummary: String {
        let best = weekBuckets.map(\.activeMinutes).max() ?? 0
        return "\(Formatting.count(totalMinutes, "active minute")) in the last \(range.rawValue) weeks, best week \(Formatting.count(best, "minute"))."
    }

    var exerciseSummary: String {
        let points = exerciseProgress
        guard let name = currentExercise?.name else {
            return "No completed sets yet."
        }
        guard let last = points.last else {
            return "No \(name) sets in the last \(range.rawValue) weeks."
        }
        let span = "\(Formatting.count(points.count, "workout")) in the last \(range.rawValue) weeks"
        if exerciseChartUsesLoad {
            let best = points.map(\.bestLoadKilograms).max() ?? 0
            let bestText = Formatting.load(.kilograms(best), units: units)
            let lastText = Formatting.load(.kilograms(last.bestLoadKilograms), units: units)
            return "\(name): best load \(bestText) across \(span), latest \(lastText)."
        }
        let best = points.map(\.bestReps).max() ?? 0
        return "\(name): best \(Formatting.count(best, "rep")) across \(span), latest \(Formatting.count(last.bestReps, "rep"))."
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

    func loadHealth() async {
        guard health.isAvailable else {
            healthState = .unavailable
            return
        }
        guard await permissions.status(of: .health) == .granted else {
            healthState = .notConnected
            return
        }
        do {
            let summary = try await health.todaySummary(now: now())
            healthState = .loaded(summary, updatedAt: now())
        } catch {
            healthState = .failed(error.localizedDescription)
        }
    }

    func connectHealth() {
        Task {
            _ = await self.permissions.request(.health)
            await self.loadHealth()
        }
    }

    func refreshHealth() {
        Task {
            await self.loadHealth()
        }
    }
}
