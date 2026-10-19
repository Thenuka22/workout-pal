import Foundation
import Observation

@MainActor
@Observable
final class RoutineDetailViewModel {
    private(set) var routine: Routine?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    let routineID: UUID
    private let routines: any RoutineRepository
    private let settings: AppSettings

    init(routineID: UUID, routines: any RoutineRepository, settings: AppSettings) {
        self.routineID = routineID
        self.routines = routines
        self.settings = settings
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    func load() async {
        do {
            routine = try await routines.routine(id: routineID)
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
}
