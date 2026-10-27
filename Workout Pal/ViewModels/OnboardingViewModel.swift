import Foundation
import Observation

enum OnboardingStep: Hashable {
    case profile
    case gender
    case height
    case fitnessLevel
    case secureUnlock
}

@MainActor
@Observable
final class OnboardingViewModel {
    let heightRange = UserPreferences.heightRange
    let unlockKind: DeviceUnlockKind

    private(set) var step: OnboardingStep = .profile
    private(set) var isFinished = false
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?
    private(set) var gender: GenderPreference?
    private(set) var fitnessLevel: FitnessLevel?
    var displayName: String
    var heightCentimetres = 170

    private let settings: AppSettings
    private let deviceAuth: any DeviceAuthenticating

    init(settings: AppSettings, deviceAuth: any DeviceAuthenticating) {
        self.settings = settings
        self.deviceAuth = deviceAuth
        unlockKind = deviceAuth.unlockKind()
        displayName = settings.preferences.displayName
        gender = settings.preferences.gender
        fitnessLevel = settings.preferences.fitnessLevel
        if let height = settings.preferences.heightCentimetres {
            heightCentimetres = height
        }
    }

    var offersSecureUnlock: Bool {
        unlockKind != .unavailable
    }

    var personaliseStepCount: Int {
        offersSecureUnlock ? 5 : 4
    }

    var personaliseStepNumber: Int {
        switch step {
        case .profile: 1
        case .gender: 2
        case .height: 3
        case .fitnessLevel: 4
        case .secureUnlock: 5
        }
    }

    var enableUnlockTitle: String {
        "Turn on \(unlockKind.title)"
    }

    var canGoBack: Bool {
        step != .profile
    }

    var canContinue: Bool {
        switch step {
        case .profile: !trimmedName.isEmpty
        case .gender: gender != nil
        case .fitnessLevel: fitnessLevel != nil
        case .height: true
        case .secureUnlock: !isAuthenticating
        }
    }

    func next() {
        switch step {
        case .profile:
            guard canContinue else {
                return
            }
            step = .gender
        case .gender:
            step = .height
        case .height:
            step = .fitnessLevel
        case .fitnessLevel:
            if offersSecureUnlock {
                step = .secureUnlock
            } else {
                finish(requiresUnlock: false)
            }
        case .secureUnlock:
            enableSecureUnlock()
        }
    }

    func back() {
        switch step {
        case .profile:
            break
        case .gender:
            step = .profile
        case .height:
            step = .gender
        case .fitnessLevel:
            step = .height
        case .secureUnlock:
            step = .fitnessLevel
        }
    }

    func skipSecureUnlock() {
        finish(requiresUnlock: false)
    }

    func select(_ gender: GenderPreference) {
        self.gender = gender
    }

    func select(_ level: FitnessLevel) {
        fitnessLevel = level
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func enableSecureUnlock() {
        guard !isAuthenticating else {
            return
        }
        isAuthenticating = true
        errorMessage = nil
        Task {
            do {
                try await self.deviceAuth.authenticate(reason: "Turn on secure unlock for Workout Pal")
                self.finish(requiresUnlock: true)
            } catch DeviceAuthenticationError.cancelled {
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isAuthenticating = false
        }
    }

    private func finish(requiresUnlock: Bool) {
        let name = trimmedName
        let gender = gender
        let height = heightCentimetres
        let level = fitnessLevel
        settings.update { preferences in
            preferences.displayName = name
            preferences.gender = gender
            preferences.heightCentimetres = height
            preferences.fitnessLevel = level
            preferences.requiresUnlock = requiresUnlock
            if let level {
                preferences.weeklyGoal = level.suggestedWeeklyGoal
            }
            preferences.hasCompletedOnboarding = true
        }
        isFinished = true
    }
}
