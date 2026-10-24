import Foundation
import Observation

enum OnboardingStep: Hashable {
    case gender
    case height
    case fitnessLevel
}

@MainActor
@Observable
final class OnboardingViewModel {
    let personaliseStepCount = 3
    let heightRange = UserPreferences.heightRange

    private(set) var step: OnboardingStep = .gender
    private(set) var isFinished = false
    private(set) var gender: GenderPreference?
    private(set) var fitnessLevel: FitnessLevel?
    var heightCentimetres = 170

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        gender = settings.preferences.gender
        fitnessLevel = settings.preferences.fitnessLevel
        if let height = settings.preferences.heightCentimetres {
            heightCentimetres = height
        }
    }

    var personaliseStepNumber: Int {
        switch step {
        case .gender: 1
        case .height: 2
        case .fitnessLevel: 3
        }
    }

    var canGoBack: Bool {
        step != .gender
    }

    var canContinue: Bool {
        switch step {
        case .gender: gender != nil
        case .fitnessLevel: fitnessLevel != nil
        case .height: true
        }
    }

    func next() {
        switch step {
        case .gender:
            step = .height
        case .height:
            step = .fitnessLevel
        case .fitnessLevel:
            finish()
        }
    }

    func back() {
        switch step {
        case .gender:
            break
        case .height:
            step = .gender
        case .fitnessLevel:
            step = .height
        }
    }

    func select(_ gender: GenderPreference) {
        self.gender = gender
    }

    func select(_ level: FitnessLevel) {
        fitnessLevel = level
    }

    private func finish() {
        let gender = gender
        let height = heightCentimetres
        let level = fitnessLevel
        settings.update { preferences in
            preferences.gender = gender
            preferences.heightCentimetres = height
            preferences.fitnessLevel = level
            if let level {
                preferences.weeklyGoal = level.suggestedWeeklyGoal
            }
            preferences.hasCompletedOnboarding = true
        }
        isFinished = true
    }
}
