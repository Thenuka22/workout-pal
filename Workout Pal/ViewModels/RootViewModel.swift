import Foundation
import Observation

enum StoreState {
    case loading
    case ready
    case failed(String)
}

@MainActor
@Observable
final class RootViewModel {
    private(set) var storeState: StoreState = .loading

    private let store: any PersistentStore
    private let settings: AppSettings

    init(store: any PersistentStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    var appearance: AppearancePreference {
        settings.preferences.appearance
    }

    func loadStore() async {
        if case .ready = storeState {
            return
        }
        storeState = .loading
        do {
            try await store.load()
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
}
