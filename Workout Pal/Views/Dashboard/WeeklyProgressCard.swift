import SwiftUI

struct WeeklyProgressCard: View {
    let summary: WeeklySummary
    let statusText: String
    var showsWeekdays = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("This week")
                .eyebrow()
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("\(summary.workoutCount) of \(summary.goal) workouts")
                    .cardTitle()
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            if showsWeekdays {
                WeekdayStrip(trainedWeekdays: summary.trainedWeekdays)
            } else {
                SegmentedProgressBar(filled: summary.workoutCount, total: summary.goal)
            }
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}

#Preview {
    VStack(spacing: AppSpacing.medium) {
        WeeklyProgressCard(
            summary: WeeklySummary(workoutCount: 3, activeMinutes: 96, completedSets: 42, goal: 4, trainedWeekdays: [2, 3, 4], volumeKilograms: 0),
            statusText: "One more to hit your goal."
        )
        WeeklyProgressCard(
            summary: WeeklySummary(workoutCount: 3, activeMinutes: 96, completedSets: 42, goal: 4, trainedWeekdays: [2, 3, 4], volumeKilograms: 0),
            statusText: "One more to hit your goal.",
            showsWeekdays: true
        )
    }
    .padding()
    .background(AppColors.surface)
}
