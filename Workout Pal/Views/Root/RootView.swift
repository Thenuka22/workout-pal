import SwiftUI

struct RootView: View {
    @State private var selection: AppDestination = .home

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppDestination.allCases) { destination in
                NavigationStack {
                    DestinationView(destination: destination)
                }
                .tabItem {
                    Label(destination.title, systemImage: destination.symbolName)
                }
                .tag(destination)
            }
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
