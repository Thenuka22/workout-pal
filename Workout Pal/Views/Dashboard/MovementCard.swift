import SwiftUI

struct MovementCard: View {
    let summary: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Your movement")
                .eyebrow()
            HStack(spacing: AppSpacing.large) {
                RingGauge(progress: summary.minutesProgress) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundStyle(AppColors.accent)
                }
                .frame(width: 76, height: 76)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("\(summary.activeMinutes)")
                        .metric(size: 34)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("active minutes this week")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("of \(summary.minutesTarget) min target · \(summary.completedSets) sets done")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    if summary.steps > 0 {
                        Text("\(Formatting.steps(summary.steps)) steps on recorded walks and runs")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}

#Preview {
    MovementCard(summary: WeeklySummary(workoutCount: 2, activeMinutes: 42, completedSets: 30, goal: 3, trainedWeekdays: [2, 5], volumeKilograms: 1240))
        .padding()
        .background(AppColors.surface)
}
