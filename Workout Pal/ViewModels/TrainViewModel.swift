import Foundation
import Observation

@MainActor
@Observable
final class TrainViewModel {
    private(set) var routines: [Routine] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    var searchText = ""

    private let repository: any RoutineRepository

    init(repository: any RoutineRepository) {
        self.repository = repository
    }

    var filteredRoutines: [Routine] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return routines
        }
        return routines.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func load() async {
        do {
            routines = try await repository.routines(ownerID: LocalProfile.ownerID)
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
}
