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

    init(
        auth: any AuthService,
        records: any AccountDataRepository,
        settings: AppSettings,
        state: any AccountStateStore
    ) {
        self.auth = auth
        self.records = records
        self.settings = settings
        self.state = state
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
    }

    func deleteLocalData() async throws {
        try await records.deleteRecords(ownerID: settings.ownerID)
        settings.reset()
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
    }
}
