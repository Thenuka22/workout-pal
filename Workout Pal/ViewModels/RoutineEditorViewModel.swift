import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class RoutineEditorViewModel {
    var draft: Routine
    private(set) var isSaving = false
    private(set) var isSaved = false
    private(set) var errorMessage: String?

    let isNew: Bool
    private let original: Routine
    private let routines: any RoutineRepository
    private let settings: AppSettings

    init(routine: Routine?, routines: any RoutineRepository, settings: AppSettings) {
        self.routines = routines
        self.settings = settings
        if let routine {
            draft = routine
            isNew = false
        } else {
            draft = Routine(
                id: UUID(),
                ownerID: settings.ownerID,
                name: "",
                notes: "",
                exercises: [],
                createdAt: .now,
                updatedAt: .now
            )
            isNew = true
        }
        original = draft
    }

    var hasChanges: Bool {
        draft != original
    }

    var title: String {
        isNew ? "New routine" : "Edit routine"
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func add(_ exercise: Exercise) {
        draft.exercises.append(.planned(for: exercise))
    }

    func moveExercises(from source: IndexSet, to destination: Int) {
        draft.exercises.move(fromOffsets: source, toOffset: destination)
    }

    func removeExercises(at offsets: IndexSet) {
        draft.exercises.remove(atOffsets: offsets)
    }

    func save() {
        guard canSave else {
            return
        }
        isSaving = true
        var routine = draft
        routine.name = routine.name.trimmingCharacters(in: .whitespaces)
        routine.notes = routine.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.updatedAt = .now
        Task {
            do {
                try await self.routines.save(routine)
                self.isSaved = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isSaving = false
        }
    }
}
