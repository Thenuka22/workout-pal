import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct AccountSessionTests {
    private let auth = FakeAuthService()
    private let records = RecordingAccountDataRepository()
    private let state = FakeAccountStateStore()
    private let store = InMemoryPreferencesStore()

    private func makeSession() -> (AccountSession, AppSettings) {
        let settings = AppSettings(store: store)
        let session = AccountSession(auth: auth, records: records, settings: settings, state: state)
        return (session, settings)
    }

    @Test func restoresTheSignedInGoogleUser() {
        auth.signedInUser = AccountUser(id: "uid-1", displayName: "Ana", email: "ana@example.com", provider: .google)
        let (session, settings) = makeSession()
        session.restore()
        #expect(session.user?.id == "uid-1")
        #expect(settings.ownerID == "uid-1")
        #expect(settings.preferences.displayName == "Ana")
    }

    @Test func restoresTheOfflineProfile() {
        state.usesOfflineProfile = true
        let (session, settings) = makeSession()
        session.restore()
        #expect(session.user?.provider == .offline)
        #expect(settings.ownerID == LocalProfile.ownerID)
    }

    @Test func staysSignedOutWithoutAnAccount() {
        let (session, _) = makeSession()
        session.restore()
        #expect(!session.isSignedIn)
    }

    @Test func firstSignInClaimsLocalWorkoutsAndPreferences() async throws {
        var local = UserPreferences.standard
        local.weeklyGoal = 5
        local.hasCompletedOnboarding = true
        store.save(local, ownerID: LocalProfile.ownerID)
        let (session, settings) = makeSession()
        try await session.signInWithGoogle()
        #expect(session.user?.id == "google-uid")
        #expect(await records.reassignedPairs() == ["local->google-uid"])
        #expect(settings.ownerID == "google-uid")
        #expect(settings.preferences.weeklyGoal == 5)
        #expect(settings.preferences.hasCompletedOnboarding)
        #expect(state.hasSeenWalkthrough)
    }

    @Test func returningAccountKeepsItsOwnPreferences() async throws {
        var mine = UserPreferences.standard
        mine.weeklyGoal = 2
        mine.hasCompletedOnboarding = true
        store.save(mine, ownerID: "google-uid")
        var local = UserPreferences.standard
        local.weeklyGoal = 6
        store.save(local, ownerID: LocalProfile.ownerID)
        let (session, settings) = makeSession()
        try await session.signInWithGoogle()
        #expect(settings.preferences.weeklyGoal == 2)
    }

    @Test func cancelledSignInLeavesYouSignedOut() async {
        auth.nextSignIn = .failure(.cancelled)
        let (session, _) = makeSession()
        await #expect(throws: AuthServiceError.cancelled) {
            try await session.signInWithGoogle()
        }
        #expect(!session.isSignedIn)
        #expect(await records.reassignedPairs().isEmpty)
    }

    @Test func signingOutReturnsToTheLocalProfile() async throws {
        let (session, settings) = makeSession()
        try await session.signInWithGoogle()
        try session.signOut()
        #expect(!session.isSignedIn)
        #expect(auth.signOutCount == 1)
        #expect(settings.ownerID == LocalProfile.ownerID)
    }

    @Test func leavingOfflineModeDoesNotCallGoogle() throws {
        let (session, _) = makeSession()
        session.continueOffline()
        #expect(state.usesOfflineProfile)
        try session.signOut()
        #expect(auth.signOutCount == 0)
        #expect(!state.usesOfflineProfile)
    }

    @Test func deletingDataClearsThisAccountOnly() async throws {
        let (session, settings) = makeSession()
        try await session.signInWithGoogle()
        settings.update { $0.hasCompletedOnboarding = true }
        try await session.deleteLocalData()
        #expect(await records.deleted == ["google-uid"])
        #expect(!settings.preferences.hasCompletedOnboarding)
    }
}
