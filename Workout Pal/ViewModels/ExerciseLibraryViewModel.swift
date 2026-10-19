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
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private(set) var refreshProgress: RefreshProgress?
    private(set) var lastRefresh: Date?
    private(set) var errorMessage: String?
    var searchText = ""
    var selectedMuscle: String?
    var selectedEquipment: String?

    private let catalog: any ExerciseCatalogRepository
    private let sync: any ExerciseCatalogSyncing

    init(catalog: any ExerciseCatalogRepository, sync: any ExerciseCatalogSyncing) {
        self.catalog = catalog
        self.sync = sync
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

    var filteredExercises: [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return exercises.filter { exercise in
            if let selectedMuscle, !exercise.primaryMuscles.contains(selectedMuscle) {
                return false
            }
            if let selectedEquipment, !exercise.equipment.contains(selectedEquipment) {
                return false
            }
            if query.isEmpty {
                return true
            }
            return exercise.name.lowercased().contains(query)
                || exercise.category.lowercased().contains(query)
                || exercise.primaryMuscles.contains { $0.lowercased().contains(query) }
        }
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
            exercises = try await catalog.exercises()
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
            exercises = try await catalog.exercises()
            lastRefresh = sync.lastRefresh()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isRefreshing = false
        refreshProgress = nil
    }
}
