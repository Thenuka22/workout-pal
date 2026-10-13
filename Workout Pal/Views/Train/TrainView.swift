import SwiftUI

struct TrainView: View {
    var body: some View {
        ContentUnavailableView(
            "No routines yet",
            systemImage: "list.bullet.rectangle",
            description: Text("Routines and the exercise library will appear here.")
        )
        .navigationTitle("Train")
    }
}

#Preview {
    NavigationStack {
        TrainView()
    }
}
