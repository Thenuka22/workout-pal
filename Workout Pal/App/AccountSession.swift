import Foundation
import Observation

@MainActor
@Observable
final class AccountSession {
    private(set) var user: AccountUser?

    private let auth: any AuthService
    private let records: any AccountDataRepository
    private let settings: AppSettings
    private let state: any AccountStateStore
    private let notifications: any NotificationScheduling

    init(
        auth: any AuthService,
        records: any AccountDataRepository,
        settings: AppSettings,
        state: any AccountStateStore,
        notifications: any NotificationScheduling
    ) {
        self.auth = auth
        self.records = records
        self.settings = settings
        self.state = state
        self.notifications = notifications
    }

    var isSignedIn: Bool {
        user != nil
    }

    var canSignInWithGoogle: Bool {
        auth.isConfigured
    }

    var hasSeenWalkthrough: Bool {
        state.hasSeenWalkthrough
    }

    func markWalkthroughSeen() {
        state.hasSeenWalkthrough = true
    }

    func restore() {
        if let current = auth.currentUser() {
            activate(current)
        } else if state.usesOfflineProfile {
            activate(.offline)
        }
    }

    func signInWithGoogle() async throws {
        let user = try await auth.signInWithGoogle()
        try await records.reassignRecords(from: LocalProfile.ownerID, to: user.id)
        state.usesOfflineProfile = false
        state.hasSeenWalkthrough = true
        activate(user, seedingFrom: LocalProfile.ownerID)
    }

    func continueOffline() {
        state.usesOfflineProfile = true
        state.hasSeenWalkthrough = true
        activate(.offline)
    }

    func signOut() throws {
        if user?.provider == .google {
            try auth.signOut()
        }
        state.usesOfflineProfile = false
        user = nil
        settings.activate(ownerID: LocalProfile.ownerID)
        Task {
            await self.notifications.cancelWorkoutReminders()
            await self.notifications.cancelRestAlert()
        }
    }

    func deleteLocalData() async throws {
        try await records.deleteRecords(ownerID: settings.ownerID)
        settings.reset()
        await notifications.cancelWorkoutReminders()
    }

    func handle(_ url: URL) -> Bool {
        auth.handle(url)
    }

    private func activate(_ user: AccountUser, seedingFrom seedOwnerID: String? = nil) {
        self.user = user
        settings.activate(ownerID: user.id, seedingFrom: seedOwnerID)
        let name = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if settings.preferences.displayName.isEmpty && !name.isEmpty {
            settings.update { $0.displayName = name }
        }
        let preferences = settings.preferences
        Task {
            if preferences.remindersEnabled && !preferences.reminderWeekdays.isEmpty {
                await self.notifications.scheduleWorkoutReminders(
                    weekdays: preferences.reminderWeekdays,
                    hour: preferences.reminderHour,
                    minute: preferences.reminderMinute
                )
            } else {
                await self.notifications.cancelWorkoutReminders()
            }
        }
    }
}
