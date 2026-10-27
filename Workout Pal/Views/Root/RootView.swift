import Foundation
import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppContainer.self) private var container
    @State private var model: RootViewModel
    @State private var navigation = AppNavigation()

    init(model: RootViewModel) {
        _model = State(initialValue: model)
    }

    private var usesSidebar: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    var body: some View {
        @Bindable var navigation = navigation
        Group {
            switch model.screen {
            case .loading:
                ProgressView("Opening your workout data")
            case .failed(let message):
                ErrorStateView(title: "Storage unavailable", message: message) {
                    model.retryLoadingStore()
                }
            case .welcome:
                WelcomeView(model: container.makeWelcomeViewModel())
            case .onboarding:
                OnboardingView(model: container.makeOnboardingViewModel())
            case .main:
                Group {
                    if usesSidebar {
                        RegularRootView(selection: $navigation.selection, displayName: model.displayName)
                    } else {
                        CompactRootView(selection: $navigation.selection)
                    }
                }
                .accessibilityHidden(model.showsLock)
            }
        }
        .lockWindow(model)
        .environment(navigation)
        .tint(AppColors.accent)
        .appearance(model.appearance)
        .task {
            await model.loadStore()
        }
        .onOpenURL { url in
            model.handleOpenURL(url)
        }
        .onChange(of: model.accountActivation) {
            navigation.selection = .home
            model.accountDidActivate()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                model.sceneDidEnterBackground()
            case .active:
                model.sceneDidBecomeActive()
            default:
                break
            }
        }
    }
}

struct DestinationView: View {
    @Environment(AppContainer.self) private var container
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .home:
            DashboardView(model: container.makeDashboardViewModel())
        case .train:
            TrainView(model: container.makeTrainViewModel())
        case .progress:
            ProgressHomeView(model: container.makeProgressViewModel())
        case .profile:
            ProfileView(model: container.makeProfileViewModel())
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return RootView(model: container.makeRootViewModel())
        .environment(container)
}
