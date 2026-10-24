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

    private let store: any PersistentStore
    private let settings: AppSettings
    private let account: AccountSession

    init(store: any PersistentStore, settings: AppSettings, account: AccountSession) {
        self.store = store
        self.settings = settings
        self.account = account
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

    var appearance: AppearancePreference {
        settings.preferences.appearance
    }

    var displayName: String {
        settings.preferences.displayName
    }

    func loadStore() async {
        if case .ready = storeState {
            return
        }
        storeState = .loading
        do {
            try await store.load()
            account.restore()
            storeState = .ready
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
}
