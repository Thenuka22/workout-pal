import SwiftUI

struct RegularRootView: View {
    @Binding var selection: AppDestination?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(AppDestination.allCases) { destination in
                    Label(destination.title, systemImage: destination.symbolName)
                        .tag(destination)
                }
            }
            .navigationTitle("Workout Pal")
        } detail: {
            NavigationStack {
                DestinationView(destination: selection ?? .home)
            }
        }
    }
}
