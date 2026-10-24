import Testing
@testable import Workout_Pal

@MainActor
struct OnboardingViewModelTests {
    @Test func cannotContinueUntilAnAnswerIsChosen() {
        let model = OnboardingViewModel(settings: AppSettings(store: InMemoryPreferencesStore()))
        #expect(model.step == .gender)
        #expect(!model.canContinue)
        #expect(!model.canGoBack)
        model.select(.female)
        #expect(model.canContinue)
    }

    @Test func finishingSavesTheProfileAndSuggestedGoal() {
        let settings = AppSettings(store: InMemoryPreferencesStore())
        let model = OnboardingViewModel(settings: settings)
        model.select(.unspecified)
        model.next()
        model.heightCentimetres = 181
        model.next()
        model.select(.advanced)
        model.next()
        #expect(model.isFinished)
        #expect(settings.preferences.hasCompletedOnboarding)
        #expect(settings.preferences.gender == .unspecified)
        #expect(settings.preferences.heightCentimetres == 181)
        #expect(settings.preferences.weeklyGoal == FitnessLevel.advanced.suggestedWeeklyGoal)
    }

    @Test func backStepsThroughThePlan() {
        let model = OnboardingViewModel(settings: AppSettings(store: InMemoryPreferencesStore()))
        model.select(.male)
        model.next()
        model.next()
        #expect(model.step == .fitnessLevel)
        model.back()
        #expect(model.step == .height)
        #expect(model.personaliseStepNumber == 2)
    }
}
