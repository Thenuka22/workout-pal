import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: RootViewModel
    @State private var selection: AppDestination? = .home

    init(model: RootViewModel) {
        _model = State(initialValue: model)
    }

    private var usesSidebar: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    var body: some View {
        Group {
            switch model.storeState {
            case .loading:
                ProgressView("Opening your workout data")
            case .failed(let message):
                ErrorStateView(title: "Storage unavailable", message: message) {
                    model.retryLoadingStore()
                }
            case .ready:
                if usesSidebar {
                    RegularRootView(selection: $selection)
                } else {
                    CompactRootView(selection: $selection)
                }
            }
        }
        .tint(AppColors.accent)
        .task {
            await model.loadStore()
        }
    }
}

struct DestinationView: View {
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .home:
            DashboardView()
        case .train:
            TrainView()
        case .progress:
            ProgressHomeView()
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return RootView(model: container.makeRootViewModel())
        .environment(container)
}
