import Foundation
import Observation

@MainActor
@Observable
final class ExerciseHistoryViewModel {
    let exerciseID: Int
    let exerciseName: String
    private(set) var history = ExerciseHistory.empty
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let repository: any WorkoutSessionRepository
    private let settings: AppSettings

    init(exerciseID: Int, exerciseName: String, repository: any WorkoutSessionRepository, settings: AppSettings) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.repository = repository
        self.settings = settings
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var hasHistory: Bool {
        !history.entries.isEmpty
    }

    var recentEntries: [ExerciseHistoryEntry] {
        Array(history.entries.prefix(3))
    }

    var countText: String {
        "Logged in \(Formatting.count(history.entries.count, "workout"))"
    }

    var bestSetText: String? {
        history.heaviest.map { "\(Formatting.load(.kilograms($0.kilograms), units: units)) × \($0.reps)" }
    }

    var mostRepsText: String? {
        history.mostReps.map { Formatting.count($0.reps, "rep") }
    }

    var oneRepMaxText: String? {
        history.bestOneRepMax.map { Formatting.load(.kilograms($0.kilograms), units: units) }
    }

    var emptyText: String {
        "You haven't logged \(exerciseName) yet. Add it to a routine and your sets will show here."
    }

    var chartUsesLoad: Bool {
        history.heaviest != nil
    }

    var chartLabel: String {
        chartUsesLoad ? "Best load (\(units.symbol))" : "Best reps"
    }

    var chartPoints: [ExerciseChartPoint] {
        let usesLoad = chartUsesLoad
        return history.entries.reversed().map { entry in
            let value = usesLoad
                ? Formatting.displayValue(kilograms: entry.sets.compactMap(\.load.kilograms).max() ?? 0, units: units)
                : Double(entry.sets.map(\.reps).max() ?? 0)
            return ExerciseChartPoint(date: entry.date, value: value)
        }
    }

    var chartSummary: String {
        guard let first = history.entries.last, let latest = history.entries.first else {
            return emptyText
        }
        var parts = ["\(countText) since \(Formatting.date(first.date))"]
        if let bestSetText {
            parts.append("best set \(bestSetText)")
        } else if let mostRepsText {
            parts.append("best \(mostRepsText)")
        }
        parts.append("latest \(Formatting.sets(latest.sets, units: units))")
        return parts.joined(separator: ", ") + "."
    }

    func setsText(_ entry: ExerciseHistoryEntry) -> String {
        Formatting.sets(entry.sets, units: units)
    }

    func load() async {
        do {
            let sessions = try await repository.completedSessions(ownerID: settings.ownerID)
            history = ExerciseHistory.make(exerciseID: exerciseID, sessions: sessions)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
