import SwiftUI

struct ProgressHomeView: View {
    var body: some View {
        ContentUnavailableView(
            "No completed workouts",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Finish a workout to see your history and charts.")
        )
        .navigationTitle("Progress")
        .screenBackground()
    }
}

#Preview {
    NavigationStack {
        ProgressHomeView()
    }
}
