import SwiftUI

struct ResumeSessionCard: View {
    let session: WorkoutSession
    let onResume: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Workout in progress")
                    .eyebrow()
                Spacer()
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(session.routineName)
                    .cardTitle()
                Text("Started \(Formatting.dateTime(session.startedAt)) · \(session.completedSetCount) of \(Formatting.count(session.totalSetCount, "set")) done")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            ProgressView(value: Double(session.completedSetCount), total: Double(max(session.totalSetCount, 1)))
                .tint(AppColors.accent)
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
