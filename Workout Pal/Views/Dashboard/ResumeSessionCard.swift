import SwiftUI

struct ResumeSessionCard: View {
    let session: WorkoutSession
    let onResume: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Workout in progress")
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(session.routineName)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Started \(Formatting.dateTime(session.startedAt)) · \(session.completedSetCount) of \(session.totalSetCount) sets done")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack(spacing: AppSpacing.small) {
                Button(action: onResume) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.primaryAction)
                Button("Discard", role: .destructive, action: onDiscard)
                    .buttonStyle(.secondaryAction)
            }
        }
        .card()
    }
}
