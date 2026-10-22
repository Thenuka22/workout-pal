import Foundation
import Observation

struct WalkthroughPage: Identifiable, Hashable {
    let id: Int
    let symbolName: String
    let title: String
    let subtitle: String
}

enum OnboardingStep: Hashable {
    case walkthrough(Int)
    case gender
    case height
    case fitnessLevel
}

@MainActor
@Observable
final class OnboardingViewModel {
    let pages = [
        WalkthroughPage(
            id: 0,
            symbolName: "figure.strengthtraining.traditional",
            title: "Start your journey toward a more active life.",
            subtitle: "Build a routine that fits your goals, your time and your everyday life."
        ),
        WalkthroughPage(
            id: 1,
            symbolName: "list.bullet.clipboard",
            title: "Build routines that fit your week.",
            subtitle: "Pick exercises from the wger library and plan your sets, reps and rest."
        ),
        WalkthroughPage(
            id: 2,
            symbolName: "chart.line.uptrend.xyaxis",
            title: "See every set add up.",
            subtitle: "Log workouts, rest on time and watch your progress week by week."
        ),
    ]
    let personaliseStepCount = 3
    let heightRange = UserPreferences.heightRange

    private(set) var step: OnboardingStep = .walkthrough(0)
    private(set) var isFinished = false
    private(set) var gender: GenderPreference?
    private(set) var fitnessLevel: FitnessLevel?
    var heightCentimetres = 170

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
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

    var personaliseStepNumber: Int {
        switch step {
        case .gender: 1
        case .height: 2
        case .fitnessLevel: 3
        case .walkthrough: 0
        }
    }

    var canContinue: Bool {
        switch step {
        case .gender: gender != nil
        case .fitnessLevel: fitnessLevel != nil
        case .walkthrough, .height: true
        }
    }

    func next() {
        switch step {
        case .walkthrough(let index):
            step = index + 1 < pages.count ? .walkthrough(index + 1) : .gender
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
        case .walkthrough(let index):
            if index > 0 {
                step = .walkthrough(index - 1)
            }
        case .gender:
            step = .walkthrough(pages.count - 1)
        case .height:
            step = .gender
        case .fitnessLevel:
            step = .height
        }
    }

    func skipWalkthrough() {
        step = .gender
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
