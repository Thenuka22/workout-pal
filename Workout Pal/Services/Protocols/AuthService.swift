import Foundation

@MainActor
protocol AuthService: AnyObject {
    var isConfigured: Bool { get }
    func currentUser() -> AccountUser?
    func signInWithGoogle() async throws -> AccountUser
    func signOut() throws
    func handle(_ url: URL) -> Bool
}

enum AuthServiceError: Error, LocalizedError, Equatable {
    case notConfigured
    case missingURLScheme
    case noWindow
    case cancelled
    case missingToken

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Google sign-in isn't set up in this build. Add GoogleService-Info.plist to the project."
        case .missingURLScheme:
            "Google sign-in needs the REVERSED_CLIENT_ID URL scheme. Set GOOGLE_REVERSED_CLIENT_ID in the build settings."
        case .noWindow:
            "Workout Pal couldn't show the Google sign-in screen. Try again."
        case .cancelled:
            "Sign-in was cancelled."
        case .missingToken:
            "Google didn't return an account. Check your connection and try again."
        }
    }
}
