import Foundation
import Observation

@MainActor
@Observable
final class TrainViewModel {
    let starterLevels = FitnessLevel.allCases

    private(set) var routines: [Routine] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    private(set) var starterMessage: String?
    private(set) var isAddingStarter = false
    var searchText = ""

    private let repository: any RoutineRepository
    private let catalog: any ExerciseCatalogRepository
    private let settings: AppSettings

    init(repository: any RoutineRepository, catalog: any ExerciseCatalogRepository, settings: AppSettings) {
        self.repository = repository
        self.catalog = catalog
        self.settings = settings
    }

    var filteredRoutines: [Routine] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return routines
        }
        return routines.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var suggestedLevel: FitnessLevel? {
        settings.preferences.fitnessLevel
    }

    var isShowingStarterMessage: Bool {
        get { starterMessage != nil }
        set {
            if !newValue {
                starterMessage = nil
            }
        }
    }

    func starterSummary(for level: FitnessLevel) -> String {
        StarterRoutines.summary(for: level)
    }

    func load() async {
        do {
            routines = try await repository.routines(ownerID: settings.ownerID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reload() {
        Task {
            await self.load()
        }
    }

    func delete(at offsets: IndexSet) {
        let visible = filteredRoutines
        let targets = offsets.compactMap { visible.indices.contains($0) ? visible[$0] : nil }
        Task {
            do {
                for routine in targets {
                    try await self.repository.deleteRoutine(id: routine.id)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            await self.load()
        }
    }

    func addStarterRoutines(level: FitnessLevel) {
        guard !isAddingStarter else {
            return
        }
        isAddingStarter = true
        Task {
            do {
                let exercises = try await self.catalog.exercises()
                if exercises.isEmpty {
                    self.starterMessage = "Download the exercise library first, then add a starter plan."
                } else {
                    let existing = Set(self.routines.map { $0.name.lowercased() })
                    let built = StarterRoutines.routines(for: level, catalog: exercises, ownerID: self.settings.ownerID)
                    let starters = built.filter { !existing.contains($0.name.lowercased()) }
                    if built.isEmpty {
                        self.starterMessage = "The exercise library has nothing for this plan yet. Refresh the library and try again."
                    } else if starters.isEmpty {
                        self.starterMessage = "These routines are already in your list."
                    } else {
                        for routine in starters {
                            try await self.repository.save(routine)
                        }
                        self.starterMessage = "Added \(starters.map(\.name).joined(separator: ", ")). Adjust the loads to suit you."
                    }
                }
                await self.load()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isAddingStarter = false
        }
    }
}
