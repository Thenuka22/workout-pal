import Foundation
import Observation

@MainActor
@Observable
final class TrainViewModel {
    private(set) var routines: [Routine] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let repository: any RoutineRepository

    init(repository: any RoutineRepository) {
        self.repository = repository
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
        let targets = offsets.compactMap { routines.indices.contains($0) ? routines[$0] : nil }
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
