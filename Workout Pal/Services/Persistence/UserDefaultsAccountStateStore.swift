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

    var hasClaimedLocalData: Bool {
        get { defaults.bool(forKey: Keys.hasClaimedLocalData) }
        set { defaults.set(newValue, forKey: Keys.hasClaimedLocalData) }
    }

    private enum Keys {
        static let usesOfflineProfile = "account.usesOfflineProfile"
        static let hasSeenWalkthrough = "account.hasSeenWalkthrough"
        static let hasClaimedLocalData = "account.hasClaimedLocalData"
        static let legacyOnboardingDone = "preferences.hasCompletedOnboarding"
    }
}
