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

    init(store: any PersistentStore) {
        self.store = store
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
