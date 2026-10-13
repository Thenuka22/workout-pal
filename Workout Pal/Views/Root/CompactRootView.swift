import SwiftUI

struct CompactRootView: View {
    @Binding var selection: AppDestination?

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppDestination.allCases) { destination in
                NavigationStack {
                    DestinationView(destination: destination)
                }
                .tabItem {
                    Label(destination.title, systemImage: destination.symbolName)
                }
                .tag(Optional(destination))
            }
        }
    }
}
