import SwiftUI
import TipKit

@main
struct WorkoutPalApp: App {
    @State private var container = AppContainer()

    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: container.makeRootViewModel())
                .environment(container)
        }
    }
}
