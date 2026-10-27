import Foundation
import Observation

@MainActor
@Observable
final class AddToRoutineViewModel {
    let exercise: Exercise
    private(set) var routines: [Routine] = []
    private(set) var isLoading = true
    private(set) var isSaving = false
    private(set) var savedMessage: String?
    private(set) var errorMessage: String?
    var newRoutineName = ""

    private let repository: any RoutineRepository
    private let settings: AppSettings
    private let now: @MainActor () -> Date

    init(
        exercise: Exercise,
        repository: any RoutineRepository,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.exercise = exercise
        self.repository = repository
        self.settings = settings
        self.now = now
    }

    var canCreateRoutine: Bool {
        !trimmedName.isEmpty && !isSaving
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func contains(_ routine: Routine) -> Bool {
        routine.exercises.contains { $0.exerciseID == exercise.id }
    }

    func load() async {
        do {
            routines = try await repository.routines(ownerID: settings.ownerID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(to routine: Routine) {
        guard !isSaving else {
            return
        }
        guard !contains(routine) else {
            savedMessage = "\(exercise.name) is already in \(routine.name)."
            return
        }
        var updated = routine
        updated.exercises.append(.planned(for: exercise))
        updated.updatedAt = now()
        save(updated, message: "Added to \(routine.name).")
    }

    func createRoutine() {
        let name = trimmedName
        guard !name.isEmpty, !isSaving else {
            return
        }
        let date = now()
        let routine = Routine(
            id: UUID(),
            ownerID: settings.ownerID,
            name: name,
            notes: "",
            exercises: [.planned(for: exercise)],
            createdAt: date,
            updatedAt: date
        )
        save(routine, message: "Created \(name) with \(exercise.name).", clearsName: true)
    }

    private var trimmedName: String {
        newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save(_ routine: Routine, message: String, clearsName: Bool = false) {
        isSaving = true
        Task {
            do {
                try await self.repository.save(routine)
                if clearsName {
                    self.newRoutineName = ""
                }
                if let index = self.routines.firstIndex(where: { $0.id == routine.id }) {
                    self.routines[index] = routine
                } else {
                    self.routines.insert(routine, at: 0)
                }
                self.savedMessage = message
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isSaving = false
        }
    }
}
