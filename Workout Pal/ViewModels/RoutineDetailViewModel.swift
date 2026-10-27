import Foundation
import Observation

@MainActor
@Observable
final class RoutineDetailViewModel {
    private(set) var routine: Routine?
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    private(set) var activeSession: WorkoutSession?
    private(set) var startErrorMessage: String?
    private(set) var deleteErrorMessage: String?
    private(set) var isDeleted = false
    var startedSession: WorkoutSession?
    var isAskingAboutActiveSession = false
    var isConfirmingDelete = false

    let routineID: UUID
    private let routines: any RoutineRepository
    private let sessions: any WorkoutSessionRepository
    private let settings: AppSettings

    init(
        routineID: UUID,
        routines: any RoutineRepository,
        sessions: any WorkoutSessionRepository,
        settings: AppSettings
    ) {
        self.routineID = routineID
        self.routines = routines
        self.sessions = sessions
        self.settings = settings
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var isShowingStartError: Bool {
        get { startErrorMessage != nil }
        set {
            if !newValue {
                startErrorMessage = nil
            }
        }
    }

    var isShowingDeleteError: Bool {
        get { deleteErrorMessage != nil }
        set {
            if !newValue {
                deleteErrorMessage = nil
            }
        }
    }

    func deleteRoutine() {
        Task {
            do {
                try await self.routines.deleteRoutine(id: self.routineID)
                self.isDeleted = true
            } catch {
                self.deleteErrorMessage = error.localizedDescription
            }
        }
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

    func startWorkout() {
        guard let routine else {
            return
        }
        Task {
            do {
                if let active = try await self.sessions.activeSession(ownerID: self.settings.ownerID) {
                    self.activeSession = active
                    self.isAskingAboutActiveSession = true
                } else {
                    self.startedSession = SessionBuilder.session(from: routine, ownerID: self.settings.ownerID)
                }
            } catch {
                self.startErrorMessage = error.localizedDescription
            }
        }
    }

    func resumeActiveSession() {
        startedSession = activeSession
    }

    func discardActiveSessionAndStart() {
        guard let routine, let active = activeSession else {
            return
        }
        Task {
            do {
                try await self.sessions.deleteSession(id: active.id)
                self.activeSession = nil
                self.startedSession = SessionBuilder.session(from: routine, ownerID: self.settings.ownerID)
            } catch {
                self.startErrorMessage = error.localizedDescription
            }
        }
    }
}
