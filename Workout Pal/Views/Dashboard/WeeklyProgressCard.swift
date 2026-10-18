import SwiftUI

struct WeeklyProgressCard: View {
    let summary: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "This week")
            HStack(spacing: AppSpacing.large) {
                Gauge(value: summary.goalProgress) {
                    Text("Goal")
                } currentValueLabel: {
                    Text("\(summary.workoutCount)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(AppColors.accent)
                .scaleEffect(1.3)
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("\(summary.workoutCount) of \(summary.goal) workouts")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(summary.activeMinutes) min active, \(summary.completedSets) sets done")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}
