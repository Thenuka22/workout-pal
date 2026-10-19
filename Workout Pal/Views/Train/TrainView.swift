import SwiftUI

struct TrainView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        List {
            Section("Library") {
                NavigationLink {
                    ExerciseLibraryView(model: container.makeExerciseLibraryViewModel())
                } label: {
                    Label("Exercise library", systemImage: "books.vertical.fill")
                }
            }
        }
        .navigationTitle("Train")
        .screenBackground()
    }
}

#Preview {
    NavigationStack {
        TrainView()
    }
    .environment(AppContainer(inMemory: true))
}
