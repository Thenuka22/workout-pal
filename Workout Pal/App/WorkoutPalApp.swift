import SwiftUI

@main
struct WorkoutPalApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(model: container.makeRootViewModel())
                .environment(container)
        }
    }
}
