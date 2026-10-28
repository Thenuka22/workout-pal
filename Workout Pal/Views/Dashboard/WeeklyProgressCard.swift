import SwiftUI

struct WeeklyProgressCard: View {
    let summary: WeeklySummary
    let statusText: String
    var showsWeekdays = false
    var streak = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("This week")
                    .eyebrow()
                Spacer()
                if streak >= 2 {
                    TagPill(text: "\(streak)-week streak", symbolName: "flame.fill")
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("\(summary.workoutCount) of \(Formatting.count(summary.goal, "workout"))")
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
