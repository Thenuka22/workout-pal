import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class FirebaseAuthService: AuthService {
    private struct GoogleTokens: Sendable {
        let idToken: String
        let accessToken: String
    }

    let isConfigured: Bool
    private let reversedClientID: String?

    init(bundle: Bundle = .main) {
        guard let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path),
              let clientID = options.clientID
        else {
            isConfigured = false
            reversedClientID = nil
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        reversedClientID = NSDictionary(contentsOfFile: path)?["REVERSED_CLIENT_ID"] as? String
        isConfigured = true
    }

    func currentUser() -> AccountUser? {
        guard isConfigured, let user = Auth.auth().currentUser else {
            return nil
        }
        return AccountUser(id: user.uid, displayName: user.displayName ?? "", email: user.email, provider: .google)
    }

    func signInWithGoogle() async throws -> AccountUser {
        guard isConfigured else {
            throw AuthServiceError.notConfigured
        }
        guard hasURLScheme else {
            throw AuthServiceError.missingURLScheme
        }
        guard let presenter = Self.topViewController() else {
            throw AuthServiceError.noWindow
        }
        let tokens = try await googleTokens(presenting: presenter)
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await firebaseUser(signingInWith: credential)
    }

    func signOut() throws {
        guard isConfigured else {
            return
        }
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    func handle(_ url: URL) -> Bool {
        isConfigured && GIDSignIn.sharedInstance.handle(url)
    }

    private var hasURLScheme: Bool {
        guard let reversedClientID, !reversedClientID.isEmpty else {
            return false
        }
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        return types.contains { type in
            (type["CFBundleURLSchemes"] as? [String] ?? []).contains(reversedClientID)
        }
    }

    private func googleTokens(presenting presenter: UIViewController) async throws -> GoogleTokens {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GoogleTokens, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { @Sendable result, error in
                if let error {
                    continuation.resume(throwing: Self.signInError(from: error))
                    return
                }
                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    continuation.resume(throwing: AuthServiceError.missingToken)
                    return
                }
                continuation.resume(returning: GoogleTokens(idToken: idToken, accessToken: user.accessToken.tokenString))
            }
        }
    }

    private func firebaseUser(signingInWith credential: AuthCredential) async throws -> AccountUser {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AccountUser, Error>) in
            Auth.auth().signIn(with: credential) { @Sendable result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let user = result?.user else {
                    continuation.resume(throwing: AuthServiceError.missingToken)
                    return
                }
                continuation.resume(returning: AccountUser(
                    id: user.uid,
                    displayName: user.displayName ?? "",
                    email: user.email,
                    provider: .google
                ))
            }
        }
    }

    nonisolated private static func signInError(from error: Error) -> Error {
        if let signInError = error as? GIDSignInError, signInError.code == .canceled {
            return AuthServiceError.cancelled
        }
        return error
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        var top = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
