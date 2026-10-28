import SwiftUI

struct RecentWorkoutCard: View {
    let session: WorkoutSession?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Last workout")
                .eyebrow()
            if let session {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(session.routineName)
                        .cardTitle()
                    Text(Formatting.dateTime(session.startedAt))
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                HStack(spacing: AppSpacing.small) {
                    TagPill(text: Formatting.minutes(fromSeconds: session.activeSeconds), symbolName: "clock")
                    TagPill(text: Formatting.count(session.completedSetCount, "set"), symbolName: "checkmark.circle")
                    TagPill(text: Formatting.count(session.exercises.count, "exercise"), symbolName: "dumbbell")
                }
            } else {
                Text("No workouts yet")
                    .cardTitle()
                Text("Start your first routine and it will show up here.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .card()
    }
}

#Preview {
    RecentWorkoutCard(session: nil)
        .padding()
        .background(AppColors.surface)
}
