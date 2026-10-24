import Testing
@testable import Workout_Pal

@MainActor
struct WelcomeViewModelTests {
    private let auth = FakeAuthService()
    private let state = FakeAccountStateStore()

    private func makeModel() -> (WelcomeViewModel, AccountSession) {
        let session = AccountSession(
            auth: auth,
            records: RecordingAccountDataRepository(),
            settings: AppSettings(store: InMemoryPreferencesStore()),
            state: state
        )
        return (WelcomeViewModel(account: session), session)
    }

    @Test func firstLaunchStartsWithTheWalkthrough() {
        let (model, _) = makeModel()
        #expect(model.step == .walkthrough(0))
        model.next()
        model.next()
        #expect(model.isLastPage)
        model.next()
        #expect(model.step == .signIn)
        #expect(state.hasSeenWalkthrough)
    }

    @Test func returningVisitorsSkipTheWalkthrough() {
        state.hasSeenWalkthrough = true
        let (model, _) = makeModel()
        #expect(model.step == .signIn)
    }

    @Test func signingInWithGoogleSignsTheAccountIn() async {
        let (model, session) = makeModel()
        model.signInWithGoogle()
        #expect(await eventually { session.isSignedIn && !model.isSigningIn })
        #expect(model.errorMessage == nil)
    }

    @Test func cancellingGoogleShowsNoError() async {
        auth.nextSignIn = .failure(.cancelled)
        let (model, session) = makeModel()
        model.signInWithGoogle()
        #expect(await eventually { !model.isSigningIn })
        #expect(model.errorMessage == nil)
        #expect(!session.isSignedIn)
    }

    @Test func failedSignInIsExplained() async {
        auth.nextSignIn = .failure(.missingToken)
        let (model, _) = makeModel()
        model.signInWithGoogle()
        #expect(await eventually { model.errorMessage != nil })
    }

    @Test func offlineModeIsOfferedOnlyWithoutFirebase() {
        auth.isConfigured = false
        let (model, session) = makeModel()
        #expect(!model.canUseGoogle)
        model.continueOffline()
        #expect(session.user?.provider == .offline)
    }
}
