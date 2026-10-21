import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var summary = WeeklySummary.empty
    private(set) var recentSession: WorkoutSession?
    private(set) var activeSession: WorkoutSession?
    private(set) var suggestedRoutine: Routine?
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    var resumingSession: WorkoutSession?

    private let sessions: any WorkoutSessionRepository
    private let routines: any RoutineRepository
    private let settings: AppSettings

    init(sessions: any WorkoutSessionRepository, routines: any RoutineRepository, settings: AppSettings) {
        self.sessions = sessions
        self.routines = routines
        self.settings = settings
    }

    var displayName: String {
        settings.preferences.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var title: String {
        displayName.isEmpty ? "Ready to move?" : displayName
    }

    var initial: String {
        let letter = displayName.prefix(1).uppercased()
        return letter.isEmpty ? "W" : letter
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    var weekStatusText: String {
        if summary.goal > 0 && summary.workoutCount >= summary.goal {
            return "Goal reached. Nice work this week."
        }
        switch summary.remainingWorkouts {
        case 1: return "One more to hit your goal."
        default:
            return summary.workoutCount == 0
                ? "Let's get the first one in."
                : "\(summary.remainingWorkouts) more to hit your goal."
        }
    }

    func load() async {
        do {
            let completed = try await sessions.completedSessions(ownerID: LocalProfile.ownerID)
            activeSession = try await sessions.activeSession(ownerID: LocalProfile.ownerID)
            let allRoutines = try await routines.routines(ownerID: LocalProfile.ownerID)
            summary = WeeklySummary.make(sessions: completed, goal: settings.preferences.weeklyGoal)
            recentSession = completed.first
            suggestedRoutine = RoutinePlanner.nextRoutine(from: allRoutines, sessions: completed)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func retry() {
        Task {
            await self.load()
        }
    }

    func resumeActiveSession() {
        resumingSession = activeSession
    }

    func discardActiveSession() {
        guard let activeSession else {
            return
        }
        Task {
            do {
                try await self.sessions.deleteSession(id: activeSession.id)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            await self.load()
        }
    }
}
