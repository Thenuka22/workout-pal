import Charts
import Foundation
import SwiftUI

struct ProgressChartsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var model: ProgressHomeViewModel

    private var chartHeight: CGFloat {
        horizontalSizeClass == .regular ? 240 : 180
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                ChipPicker(options: ProgressRange.allCases, selection: $model.range) { $0.title }
                minutesCard
                workoutsCard
                if model.totalActivities > 0 {
                    walksCard
                }
                thisWeekTiles
                HealthTodayCard(
                    state: model.healthState,
                    todayActiveMinutes: model.todayActiveMinutes,
                    units: model.units,
                    onConnect: { model.connectHealth() },
                    onRefresh: { model.refreshHealth() }
                )
                exerciseCard
                recordsCard
                Text("Your activity stays on your device.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .task {
            await model.loadHealth()
        }
    }

    private var minutesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Active minutes")
                .eyebrow()
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text("\(model.totalMinutes)")
                    .metric(size: 34)
                    .foregroundStyle(AppColors.textPrimary)
                Text("min in the last \(model.range.rawValue) weeks")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Chart(model.weekBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", bucket.activeMinutes)
                )
                .foregroundStyle(barColor(for: bucket))
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: chartHeight)
            .accessibilityLabel(model.minutesSummary)
            Text(model.minutesSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var workoutsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Workouts")
                .eyebrow()
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text("\(model.totalWorkouts)")
                    .metric(size: 34)
                    .foregroundStyle(AppColors.textPrimary)
                Text("in the last \(model.range.rawValue) weeks")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Chart(model.weekBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Workouts", bucket.workouts)
                )
                .foregroundStyle(barColor(for: bucket))
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: chartHeight)
            .accessibilityLabel(model.workoutsSummary)
            Text(model.workoutsSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var walksCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Walks & runs")
                .eyebrow()
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text(Formatting.steps(model.totalSteps))
                    .metric(size: 34)
                    .foregroundStyle(AppColors.textPrimary)
                Text("steps in the last \(model.range.rawValue) weeks")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Chart(model.weekBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Steps", bucket.steps)
                )
                .foregroundStyle(barColor(for: bucket))
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: chartHeight)
            .accessibilityLabel(model.walksSummary)
            Text(model.walksSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private var thisWeekTiles: some View {
        let summary = model.weeklySummary
        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("This week")
                .cardTitle()
            AdaptiveStack {
                StatTile(
                    title: "Workouts",
                    value: "\(summary.workoutCount) of \(summary.goal)",
                    caption: "weekly goal",
                    dotColor: AppColors.infoOrange
                )
                StatTile(
                    title: "Active time",
                    value: "\(summary.activeMinutes) min",
                    caption: "of \(summary.minutesTarget) min",
                    dotColor: AppColors.infoBlue
                )
                StatTile(
                    title: "Volume",
                    value: model.weeklyVolumeText,
                    caption: "lifted",
                    dotColor: AppColors.infoPurple
                )
            }
            AdaptiveStack {
                StatTile(
                    title: "Walks & runs",
                    value: model.weeklyStepsText,
                    caption: "recorded this week",
                    dotColor: AppColors.accent
                )
                StatTile(
                    title: "Goal streak",
                    value: model.streakText,
                    caption: "weeks hitting your goal",
                    dotColor: AppColors.warning
                )
            }
            Text("Volume is load × reps of completed sets. Bodyweight sets aren't counted.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var recordsCard: some View {
        if !model.records.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("Personal records · all time")
                        .eyebrow()
                    Spacer()
                    NavigationLink {
                        PersonalRecordsView(records: model.allRecords, units: model.units)
                    } label: {
                        Text("See all")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                }
                ForEach(model.records) { record in
                    NavigationLink(value: ExerciseOption(id: record.exerciseID, name: record.exerciseName)) {
                        PersonalRecordRow(record: record, units: model.units)
                    }
                    .buttonStyle(.plain)
                }
            }
            .card()
        }
    }

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Exercise progress")
                .eyebrow()
            if model.exerciseOptions.isEmpty {
                Text("Complete sets in a workout to track an exercise.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                Picker("Exercise", selection: $model.currentExerciseID) {
                    ForEach(model.exerciseOptions) { option in
                        Text(option.name).tag(option.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.accent)
                if let exercise = model.currentExercise {
                    NavigationLink(value: exercise) {
                        Text("View history")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                }
                let label = model.exerciseChartLabel
                Chart(model.exerciseChartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value(label, point.value)
                    )
                    .foregroundStyle(AppColors.accent)
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value(label, point.value)
                    )
                    .foregroundStyle(AppColors.accent)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .frame(height: chartHeight)
                .accessibilityLabel(model.exerciseSummary)
                Text(model.exerciseSummary)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .card()
    }

    private func barColor(for bucket: WeekBucket) -> Color {
        bucket.weekStart == model.currentWeekStart ? AppColors.accent : AppColors.accent.opacity(0.35)
    }
}
