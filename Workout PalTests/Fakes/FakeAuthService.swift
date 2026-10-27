import Foundation
@testable import Workout_Pal

@MainActor
final class FakeAuthService: AuthService {
    var isConfigured = true
    var signedInUser: AccountUser?
    var nextSignIn: Result<AccountUser, AuthServiceError> = .success(
        AccountUser(id: "google-uid", displayName: "Induwara Thenuka", email: "induwara@example.com", provider: .google)
    )
    private(set) var signOutCount = 0
    private(set) var handledURLs: [URL] = []

    func currentUser() -> AccountUser? {
        signedInUser
    }

    func signInWithGoogle() async throws -> AccountUser {
        let user = try nextSignIn.get()
        signedInUser = user
        return user
    }

    func signOut() throws {
        signOutCount += 1
        signedInUser = nil
    }

    func handle(_ url: URL) -> Bool {
        handledURLs.append(url)
        return true
    }
}

@MainActor
final class FakeAccountStateStore: AccountStateStore {
    var usesOfflineProfile = false
    var hasSeenWalkthrough = false
    var hasClaimedLocalData = false
}

actor RecordingAccountDataRepository: AccountDataRepository {
    private(set) var reassigned: [(from: String, to: String)] = []
    private(set) var deleted: [String] = []

    func reassignRecords(from oldOwnerID: String, to newOwnerID: String) async throws {
        reassigned.append((oldOwnerID, newOwnerID))
    }

    func deleteRecords(ownerID: String) async throws {
        deleted.append(ownerID)
    }

    func reassignedPairs() -> [String] {
        reassigned.map { "\($0.from)->\($0.to)" }
    }
}
