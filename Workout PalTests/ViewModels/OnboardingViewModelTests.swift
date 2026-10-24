import Testing
@testable import Workout_Pal

@MainActor
struct OnboardingViewModelTests {
    private let deviceAuth = FakeDeviceAuth()

    private func makeModel(settings: AppSettings = AppSettings(store: InMemoryPreferencesStore())) -> OnboardingViewModel {
        OnboardingViewModel(settings: settings, deviceAuth: deviceAuth)
    }

    private func answerQuestions(_ model: OnboardingViewModel) {
        model.select(.unspecified)
        model.next()
        model.heightCentimetres = 181
        model.next()
        model.select(.advanced)
        model.next()
    }

    @Test func cannotContinueUntilAnAnswerIsChosen() {
        let model = makeModel()
        #expect(model.step == .gender)
        #expect(!model.canContinue)
        #expect(!model.canGoBack)
        model.select(.female)
        #expect(model.canContinue)
    }

    @Test func withoutAPasscodeThePlanFinishesAfterThreeSteps() {
        deviceAuth.kind = .unavailable
        let settings = AppSettings(store: InMemoryPreferencesStore())
        let model = makeModel(settings: settings)
        #expect(model.personaliseStepCount == 3)
        answerQuestions(model)
        #expect(model.isFinished)
        #expect(settings.preferences.hasCompletedOnboarding)
        #expect(settings.preferences.gender == .unspecified)
        #expect(settings.preferences.heightCentimetres == 181)
        #expect(settings.preferences.weeklyGoal == FitnessLevel.advanced.suggestedWeeklyGoal)
        #expect(!settings.preferences.requiresUnlock)
    }

    @Test func secureUnlockCanBeTurnedOn() async {
        let settings = AppSettings(store: InMemoryPreferencesStore())
        let model = makeModel(settings: settings)
        answerQuestions(model)
        #expect(model.step == .secureUnlock)
        model.next()
        #expect(await eventually { model.isFinished })
        #expect(settings.preferences.requiresUnlock)
        #expect(deviceAuth.attempts == 1)
    }

    @Test func secureUnlockCanBeSkipped() {
        let settings = AppSettings(store: InMemoryPreferencesStore())
        let model = makeModel(settings: settings)
        answerQuestions(model)
        model.skipSecureUnlock()
        #expect(model.isFinished)
        #expect(!settings.preferences.requiresUnlock)
        #expect(deviceAuth.attempts == 0)
    }

    @Test func cancelledFaceIDKeepsYouOnTheStep() async {
        deviceAuth.failure = .cancelled
        let model = makeModel()
        answerQuestions(model)
        model.next()
        #expect(await eventually { deviceAuth.attempts == 1 && !model.isAuthenticating })
        #expect(!model.isFinished)
        #expect(model.step == .secureUnlock)
    }

    @Test func backStepsThroughThePlan() {
        let model = makeModel()
        model.select(.male)
        model.next()
        model.next()
        #expect(model.step == .fitnessLevel)
        model.back()
        #expect(model.step == .height)
        #expect(model.personaliseStepNumber == 2)
    }
}
