import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var summary = WeeklySummary.empty
    private(set) var recentSession: WorkoutSession?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let sessions: any WorkoutSessionRepository
    private let settings: AppSettings

    init(sessions: any WorkoutSessionRepository, settings: AppSettings) {
        self.sessions = sessions
        self.settings = settings
    }

    func load() async {
        do {
            let completed = try await sessions.completedSessions(ownerID: LocalProfile.ownerID)
            summary = WeeklySummary.make(sessions: completed, goal: settings.preferences.weeklyGoal)
            recentSession = completed.first
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
}
