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
    private(set) var pendingStarterLevel: FitnessLevel?
    var searchText = ""

    private let repository: any RoutineRepository
    private let catalog: any ExerciseCatalogRepository
    private let sync: any ExerciseCatalogSyncing
    private let settings: AppSettings

    init(
        repository: any RoutineRepository,
        catalog: any ExerciseCatalogRepository,
        sync: any ExerciseCatalogSyncing,
        settings: AppSettings
    ) {
        self.repository = repository
        self.catalog = catalog
        self.sync = sync
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

    func downloadLibraryForStarter() {
        guard let level = pendingStarterLevel, !isAddingStarter else {
            return
        }
        pendingStarterLevel = nil
        isAddingStarter = true
        Task {
            do {
                _ = try await self.sync.refresh { _, _ in }
            } catch {
                self.isAddingStarter = false
                self.starterMessage = "Couldn't download the exercise library. Check your connection and try again."
                return
            }
            self.isAddingStarter = false
            self.addStarterRoutines(level: level)
        }
    }

    func cancelStarterDownload() {
        pendingStarterLevel = nil
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
                    self.pendingStarterLevel = level
                    self.starterMessage = "Starter plans are built from the exercise library. Download it now? It needs an internet connection and takes about a minute."
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
