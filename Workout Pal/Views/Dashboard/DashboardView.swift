import SwiftUI

struct DashboardView: View {
    var body: some View {
        ContentUnavailableView(
            "No workouts yet",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Create a routine in Train and log your first session.")
        )
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
