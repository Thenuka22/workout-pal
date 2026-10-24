import Foundation

@MainActor
final class UserDefaultsAccountStateStore: AccountStateStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var usesOfflineProfile: Bool {
        get { defaults.bool(forKey: Keys.usesOfflineProfile) }
        set { defaults.set(newValue, forKey: Keys.usesOfflineProfile) }
    }

    var hasSeenWalkthrough: Bool {
        get {
            defaults.bool(forKey: Keys.hasSeenWalkthrough) || defaults.bool(forKey: Keys.legacyOnboardingDone)
        }
        set { defaults.set(newValue, forKey: Keys.hasSeenWalkthrough) }
    }

    private enum Keys {
        static let usesOfflineProfile = "account.usesOfflineProfile"
        static let hasSeenWalkthrough = "account.hasSeenWalkthrough"
        static let legacyOnboardingDone = "preferences.hasCompletedOnboarding"
    }
}
