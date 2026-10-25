import Foundation
import Observation

struct RefreshProgress: Hashable, Sendable {
    var done: Int
    var total: Int
}

@MainActor
@Observable
final class ExerciseLibraryViewModel {
    private(set) var exercises: [Exercise] = []
    private(set) var items: [CatalogItem] = []
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private(set) var refreshProgress: RefreshProgress?
    private(set) var lastRefresh: Date?
    private(set) var errorMessage: String?
    var searchText = ""
    var selectedMuscle: String?
    var selectedEquipment: String?
    var scope: LibraryScope
    var difficulty: ExerciseDifficulty?

    private let catalog: any ExerciseCatalogRepository
    private let sync: any ExerciseCatalogSyncing
    private let settings: AppSettings

    init(catalog: any ExerciseCatalogRepository, sync: any ExerciseCatalogSyncing, settings: AppSettings) {
        self.catalog = catalog
        self.sync = sync
        self.settings = settings
        scope = settings.preferences.fitnessLevel == nil ? .all : .forYou
    }

    var hasFilters: Bool {
        selectedMuscle != nil || selectedEquipment != nil
    }

    var muscleOptions: [String] {
        Set(exercises.flatMap(\.primaryMuscles)).sorted()
    }

    var equipmentOptions: [String] {
        Set(exercises.flatMap(\.equipment)).sorted()
    }

    var scopeOptions: [LibraryScope] {
        CatalogGrouping.scopes(for: items)
    }

    var sections: [ExerciseSection] {
        CatalogGrouping.sections(
            items: items,
            scope: scope,
            difficulty: difficulty,
            query: searchText,
            muscle: selectedMuscle,
            equipment: selectedEquipment,
            fitnessLevel: settings.preferences.fitnessLevel
        )
    }

    var filteredExercises: [Exercise] {
        sections.flatMap(\.items).map(\.exercise)
    }

    var scopeCaption: String? {
        guard scope == .forYou, difficulty == nil, let level = settings.preferences.fitnessLevel else {
            return nil
        }
        return "Picked for your \(level.title.lowercased()) level. Levels are estimated from the exercise and its equipment."
    }

    var statusText: String {
        if let progress = refreshProgress, progress.total > 0 {
            return "Downloading exercises \(progress.done) of \(progress.total)"
        }
        return isRefreshing ? "Downloading exercises" : "Loading exercises"
    }

    var attributionText: String {
        var text = "Exercise data from wger.de, shared under CC-BY-SA licences."
        if let lastRefresh {
            text += " Last updated \(Formatting.dateTime(lastRefresh))."
        }
        return text
    }

    func clearFilters() {
        selectedMuscle = nil
        selectedEquipment = nil
    }

    func load() async {
        do {
            show(try await catalog.exercises())
            lastRefresh = sync.lastRefresh()
            errorMessage = nil
            isLoading = false
            if exercises.isEmpty && lastRefresh == nil {
                await downloadCatalogue()
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func refresh() {
        Task {
            await self.downloadCatalogue()
        }
    }

    private func show(_ exercises: [Exercise]) {
        self.exercises = exercises
        items = CatalogGrouping.items(from: exercises)
    }

    private func downloadCatalogue() async {
        guard !isRefreshing else {
            return
        }
        isRefreshing = true
        refreshProgress = nil
        do {
            _ = try await sync.refresh { [weak self] done, total in
                self?.refreshProgress = RefreshProgress(done: done, total: total)
            }
            show(try await catalog.exercises())
            lastRefresh = sync.lastRefresh()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isRefreshing = false
        refreshProgress = nil
    }
}
