import Foundation
import Observation

enum ProgressRange: Int, CaseIterable, Identifiable {
    case fourWeeks = 4
    case twelveWeeks = 12
    case twentySixWeeks = 26

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) weeks"
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
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    var range: ProgressRange = .twelveWeeks
    var selectedExerciseID: Int?

    private let repository: any WorkoutSessionRepository
    private let settings: AppSettings

    init(repository: any WorkoutSessionRepository, settings: AppSettings) {
        self.repository = repository
        self.settings = settings
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var historyGroups: [HistoryGroup] {
        ProgressCalculator.groupByWeek(sessions: sessions)
    }

    var weekBuckets: [WeekBucket] {
        ProgressCalculator.weekBuckets(sessions: sessions, weeks: range.rawValue)
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
        let buckets = weekBuckets
        let total = buckets.reduce(0) { $0 + $1.workouts }
        let best = buckets.map(\.workouts).max() ?? 0
        return "\(total) workouts in the last \(buckets.count) weeks, best week \(best)."
    }

    var minutesSummary: String {
        let buckets = weekBuckets
        let total = buckets.reduce(0) { $0 + $1.activeMinutes }
        let best = buckets.map(\.activeMinutes).max() ?? 0
        return "\(total) active minutes in the last \(buckets.count) weeks, best week \(best) minutes."
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
            sessions = try await repository.completedSessions(ownerID: LocalProfile.ownerID)
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
