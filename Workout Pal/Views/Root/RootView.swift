import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: AppDestination? = .home

    private var usesSidebar: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    var body: some View {
        if usesSidebar {
            RegularRootView(selection: $selection)
        } else {
            CompactRootView(selection: $selection)
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
    RootView()
}
