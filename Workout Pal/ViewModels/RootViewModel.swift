import Foundation
import Observation

enum StoreState {
    case loading
    case ready
    case failed(String)
}

enum RootScreen: Equatable {
    case loading
    case failed(String)
    case welcome
    case onboarding
    case main
}

@MainActor
@Observable
final class RootViewModel {
    private(set) var storeState: StoreState = .loading
    private(set) var isLocked = false
    private(set) var isUnlocking = false
    private(set) var unlockMessage: String?

    private let store: any PersistentStore
    private let settings: AppSettings
    private let account: AccountSession
    private let deviceAuth: any DeviceAuthenticating
    @ObservationIgnored private var returnedFromBackground = false

    init(
        store: any PersistentStore,
        settings: AppSettings,
        account: AccountSession,
        deviceAuth: any DeviceAuthenticating
    ) {
        self.store = store
        self.settings = settings
        self.account = account
        self.deviceAuth = deviceAuth
    }

    var screen: RootScreen {
        switch storeState {
        case .loading:
            return .loading
        case .failed(let message):
            return .failed(message)
        case .ready:
            if !account.isSignedIn {
                return .welcome
            }
            return settings.preferences.hasCompletedOnboarding ? .main : .onboarding
        }
    }

    var showsLock: Bool {
        isLocked && screen == .main
    }

    var unlockTitle: String {
        "Unlock with \(deviceAuth.unlockKind().title)"
    }

    var unlockSymbolName: String {
        deviceAuth.unlockKind().symbolName
    }

    var appearance: AppearancePreference {
        settings.preferences.appearance
    }

    var displayName: String {
        settings.preferences.displayName
    }

    var accountActivation: Int {
        account.activationCount
    }

    private var accountRequiresUnlock: Bool {
        account.isSignedIn && settings.preferences.hasCompletedOnboarding && settings.preferences.requiresUnlock
    }

    func loadStore() async {
        if case .ready = storeState {
            return
        }
        storeState = .loading
        do {
            try await store.load()
            account.restore()
            isLocked = accountRequiresUnlock
            storeState = .ready
            if showsLock {
                unlock()
            }
        } catch {
            storeState = .failed(error.localizedDescription)
        }
    }

    func retryLoadingStore() {
        Task {
            await self.loadStore()
        }
    }

    func handleOpenURL(_ url: URL) {
        _ = account.handle(url)
    }

    func accountDidActivate() {
        guard case .ready = storeState else {
            return
        }
        isLocked = accountRequiresUnlock
        unlockMessage = nil
        if showsLock {
            unlock()
        }
    }

    func sceneDidEnterBackground() {
        returnedFromBackground = true
        if accountRequiresUnlock {
            isLocked = true
            unlockMessage = nil
        }
    }

    func sceneDidBecomeActive() {
        guard returnedFromBackground else {
            return
        }
        returnedFromBackground = false
        if showsLock {
            unlock()
        }
    }

    func unlock() {
        guard isLocked, !isUnlocking else {
            return
        }
        isUnlocking = true
        Task {
            do {
                try await self.deviceAuth.authenticate(reason: "Unlock your workout history")
                self.isLocked = false
                self.unlockMessage = nil
            } catch DeviceAuthenticationError.cancelled {
                self.unlockMessage = nil
            } catch {
                self.unlockMessage = error.localizedDescription
            }
            self.isUnlocking = false
        }
    }

    func signOutFromLock() {
        do {
            try account.signOut()
            isLocked = false
            unlockMessage = nil
        } catch {
            unlockMessage = error.localizedDescription
        }
    }
}
