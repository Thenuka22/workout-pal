import Charts
import Foundation
import SwiftUI

/// The short "Your history" card on an exercise's screen.
struct ExerciseHistoryCard: View {
    let model: ExerciseHistoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Your history")
                .eyebrow()
            if model.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if model.hasHistory {
                Text(model.countText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                ExerciseBestsRow(model: model)
                ForEach(model.recentEntries) { entry in
                    ExerciseHistoryEntryRow(entry: entry, setsText: model.setsText(entry))
                }
                NavigationLink {
                    ExerciseHistoryView(model: model)
                } label: {
                    Label("See all", systemImage: "chevron.right")
                        .labelStyle(.titleOnly)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
            } else {
                Text(model.emptyText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
    }
}

/// Every logged workout for one exercise, with its bests and a chart.
struct ExerciseHistoryView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: ExerciseHistoryViewModel

    init(model: ExerciseHistoryViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        List {
            if model.hasHistory {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(model.countText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    ExerciseBestsRow(model: model)
                }
                .card()
                .plainRow(top: AppSpacing.medium)
                chartCard
                    .plainRow()
                Text("Workouts")
                    .eyebrow()
                    .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
                ForEach(model.history.entries) { entry in
                    ExerciseHistoryEntryRow(entry: entry, setsText: model.setsText(entry))
                        .cardRow()
                }
            }
        }
        .listStyle(.plain)
        .screenBackground()
        .navigationTitle(model.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .overlay {
            if model.isLoading {
                ProgressView()
            } else if let message = model.errorMessage {
                ContentUnavailableView("Could not load your history", systemImage: "exclamationmark.triangle", description: Text(message))
            } else if !model.hasHistory {
                ContentUnavailableView("Nothing logged yet", systemImage: "dumbbell", description: Text(model.emptyText))
            }
        }
        .task {
            await model.load()
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(model.chartLabel)
                .eyebrow()
            let label = model.chartLabel
            Chart(model.chartPoints) { point in
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
            .frame(height: horizontalSizeClass == .regular ? 240 : 180)
            .accessibilityLabel(model.chartSummary)
            Text(model.chartSummary)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }
}

private struct ExerciseBestsRow: View {
    let model: ExerciseHistoryViewModel

    var body: some View {
        AdaptiveStack(spacing: AppSpacing.medium) {
            if let bestSet = model.bestSetText {
                best(title: "Best set", value: bestSet)
            }
            if let oneRepMax = model.oneRepMaxText {
                best(title: "Est. 1RM", value: oneRepMax)
                    .accessibilityLabel("Estimated one rep max, \(oneRepMax)")
            }
            if model.bestSetText == nil, let mostReps = model.mostRepsText {
                best(title: "Most reps", value: mostReps)
            }
        }
    }

    private func best(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ExerciseHistoryEntryRow: View {
    let entry: ExerciseHistoryEntry
    let setsText: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatting.date(entry.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(entry.workoutName)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Text(setsText)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
