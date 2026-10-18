import SwiftUI

struct RecentWorkoutCard: View {
    let session: WorkoutSession?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Recent workout")
            if let session {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(session.routineName)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(Formatting.dateTime(session.startedAt))
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                HStack(spacing: AppSpacing.large) {
                    Label(Formatting.minutes(fromSeconds: session.activeSeconds), systemImage: "clock")
                    Label("\(session.completedSetCount) sets", systemImage: "checkmark.circle")
                    Label("\(session.exercises.count) exercises", systemImage: "dumbbell")
                }
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
            } else {
                Text("No workouts yet")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Create a routine in Train and log your first session.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .card()
    }
}
