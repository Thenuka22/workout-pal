import Foundation
import Observation

struct WalkthroughPage: Identifiable, Hashable {
    let id: Int
    let symbolName: String
    let title: String
    let subtitle: String
}

enum WelcomeStep: Hashable {
    case walkthrough(Int)
    case signIn
}

@MainActor
@Observable
final class WelcomeViewModel {
    let pages = [
        WalkthroughPage(
            id: 0,
            symbolName: "figure.strengthtraining.traditional",
            title: "Start your journey toward a more active life.",
            subtitle: "Build a routine that fits your goals, your time and your everyday life."
        ),
        WalkthroughPage(
            id: 1,
            symbolName: "camera.viewfinder",
            title: "Count reps and steps for you.",
            subtitle: "Track walks and runs, and let the camera count your squats and jumping jacks."
        ),
        WalkthroughPage(
            id: 2,
            symbolName: "chart.line.uptrend.xyaxis",
            title: "See every set add up.",
            subtitle: "Log workouts, rest on time and watch your progress week by week."
        ),
    ]

    private(set) var step: WelcomeStep
    private(set) var isSigningIn = false
    private(set) var errorMessage: String?

    private let account: AccountSession

    init(account: AccountSession) {
        self.account = account
        step = account.hasSeenWalkthrough ? .signIn : .walkthrough(0)
    }

    var walkthroughIndex: Int {
        get {
            if case .walkthrough(let index) = step {
                return index
            }
            return pages.count - 1
        }
        set {
            step = .walkthrough(min(max(newValue, 0), pages.count - 1))
        }
    }

    var isLastPage: Bool {
        walkthroughIndex == pages.count - 1
    }

    var canUseGoogle: Bool {
        account.canSignInWithGoogle
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func next() {
        guard case .walkthrough(let index) = step else {
            return
        }
        if index + 1 < pages.count {
            step = .walkthrough(index + 1)
        } else {
            showSignIn()
        }
    }

    func skipWalkthrough() {
        showSignIn()
    }

    func showWalkthrough() {
        step = .walkthrough(0)
    }

    func signInWithGoogle() {
        guard !isSigningIn else {
            return
        }
        isSigningIn = true
        errorMessage = nil
        Task {
            do {
                try await self.account.signInWithGoogle()
            } catch AuthServiceError.cancelled {
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isSigningIn = false
        }
    }

    func continueOffline() {
        account.continueOffline()
    }

    private func showSignIn() {
        account.markWalkthroughSeen()
        step = .signIn
    }
}
