import Observation

@MainActor
@Observable
final class AppContainer {
    private let stack: CoreDataStack

    init(inMemory: Bool = false) {
        stack = CoreDataStack(inMemory: inMemory)
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(store: stack)
    }
}
