import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var summary = WeeklySummary.empty
    private(set) var recentSession: WorkoutSession?
    private(set) var activeSession: WorkoutSession?
    private(set) var activeActivity: ActivitySession?
    private(set) var suggestedRoutine: Routine?
    private(set) var weekStreak = 0
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    var resumingSession: WorkoutSession?

    private let sessions: any WorkoutSessionRepository
    private let activities: any ActivitySessionRepository
    private let routines: any RoutineRepository
    private let settings: AppSettings

    init(
        sessions: any WorkoutSessionRepository,
        activities: any ActivitySessionRepository,
        routines: any RoutineRepository,
        settings: AppSettings
    ) {
        self.sessions = sessions
        self.activities = activities
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
        let salutation = switch hour {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
        return displayName.isEmpty ? salutation : "\(salutation),"
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
            let completed = try await sessions.completedSessions(ownerID: settings.ownerID)
            let walks = try await activities.completedActivities(ownerID: settings.ownerID)
            activeSession = try await sessions.activeSession(ownerID: settings.ownerID)
            activeActivity = try await activities.activeActivity(ownerID: settings.ownerID)
            let allRoutines = try await routines.routines(ownerID: settings.ownerID)
            summary = WeeklySummary.make(sessions: completed, activities: walks, goal: settings.preferences.weeklyGoal)
            weekStreak = StreakCalculator.weekStreak(sessions: completed, goal: settings.preferences.weeklyGoal)
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
