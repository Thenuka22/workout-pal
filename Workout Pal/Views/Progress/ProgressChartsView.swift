import Charts
import Foundation
import SwiftUI

struct ProgressChartsView: View {
    @Bindable var model: ProgressHomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Picker("Range", selection: $model.range) {
                    ForEach(ProgressRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                workoutsChart
                minutesChart
                exerciseChart
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
    }

    private var workoutsChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Workouts per week")
            Chart(model.weekBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Workouts", bucket.workouts)
                )
                .foregroundStyle(AppColors.accent)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 200)
            .accessibilityLabel(model.workoutsSummary)
            Text(model.workoutsSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var minutesChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Active minutes per week")
            Chart(model.weekBuckets) { bucket in
                LineMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", bucket.activeMinutes)
                )
                .foregroundStyle(AppColors.accent)
                PointMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", bucket.activeMinutes)
                )
                .foregroundStyle(AppColors.accent)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 200)
            .accessibilityLabel(model.minutesSummary)
            Text(model.minutesSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var exerciseChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Exercise progress")
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
                .frame(height: 200)
                .accessibilityLabel(model.exerciseSummary)
                Text(model.exerciseSummary)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .card()
    }
}
