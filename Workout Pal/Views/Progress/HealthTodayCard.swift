import Foundation
import SwiftUI

struct HealthTodayCard: View {
    let state: HealthCardState
    let todayActiveMinutes: Int
    let units: UnitPreference
    let onConnect: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Today")
                .cardTitle()
            HStack(alignment: .top, spacing: AppSpacing.small) {
                StatTile(
                    title: "Steps",
                    value: stepsText,
                    caption: "of \(Formatting.steps(HealthDaySummary.dailyStepGoal)) · Apple Health",
                    dotColor: AppColors.accent
                )
                StatTile(
                    title: "Active time",
                    value: "\(todayActiveMinutes) min",
                    caption: "recorded in Workout Pal",
                    dotColor: AppColors.infoOrange
                )
                StatTile(
                    title: "Distance",
                    value: distanceText,
                    caption: "walk + run · Apple Health",
                    dotColor: AppColors.infoBlue
                )
            }
            statusCard
        }
    }

    private var summary: HealthDaySummary? {
        if case .loaded(let summary, _) = state {
            return summary
        }
        return nil
    }

    private var stepsText: String {
        guard let summary else {
            return "–"
        }
        return summary.steps.map { Formatting.steps($0) } ?? "No data"
    }

    private var distanceText: String {
        guard let summary else {
            return "–"
        }
        return summary.distanceMeters.map { Formatting.distance(meters: $0, units: units) } ?? "No data"
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(AppColors.onAccent)
                    .frame(width: 40, height: 40)
                    .background(AppColors.infoOrange, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Apple Health")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                switch state {
                case .notConnected:
                    Button("Connect", action: onConnect)
                        .font(.subheadline.weight(.semibold))
                case .loaded, .failed:
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh Apple Health data")
                case .loading:
                    ProgressView()
                case .unavailable:
                    EmptyView()
                }
            }
            if let summary, !summary.otherWorkouts.isEmpty {
                Divider()
                    .overlay(AppColors.outline)
                Text("Other workouts in Apple Health this week")
                    .eyebrow()
                ForEach(summary.otherWorkouts.prefix(3)) { workout in
                    HStack {
                        Text(workout.name)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text("\(Formatting.minutes(fromSeconds: workout.durationSeconds)) · \(workout.sourceName)")
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    .font(.subheadline)
                }
            }
        }
        .card()
    }

    private var statusText: String {
        switch state {
        case .unavailable:
            "Apple Health isn't available on this device."
        case .notConnected:
            "Connect to show your steps and distance. Workout Pal only reads them."
        case .loading:
            "Checking Apple Health…"
        case .loaded(_, let updatedAt):
            "Updated \(updatedAt.formatted(date: .omitted, time: .shortened)). Shown separately from your Workout Pal history."
        case .failed(let message):
            message
        }
    }
}
