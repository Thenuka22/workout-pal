import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutFinishSummary
    let units: UnitPreference
    let shareText: String
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Workout complete")
                        .eyebrow()
                    Text(summary.routineName)
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(AppSpacing.medium)
                .photoCard(AppImages.friendsWide, minHeight: 200)
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    StatTile(
                        title: "Active time",
                        value: Formatting.minutes(fromSeconds: summary.activeSeconds),
                        dotColor: AppColors.infoBlue
                    )
                    StatTile(title: "Sets done", value: "\(summary.completedSets)", dotColor: AppColors.infoOrange)
                    StatTile(
                        title: "Volume",
                        value: Formatting.volume(kilograms: summary.volumeKilograms, units: units),
                        dotColor: AppColors.infoPurple
                    )
                }
                if summary.records.isEmpty {
                    Text("Nice work. Your history and progress are up to date.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Label("New personal records", systemImage: "trophy.fill")
                            .font(.headline)
                            .foregroundStyle(AppColors.warning)
                        ForEach(summary.records) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.exerciseName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text(record.kind.title)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                                Text(Formatting.record(record, units: units))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(AppColors.accent)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .card()
                }
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppSpacing.small) {
                ShareLink(item: shareText) {
                    Label("Share workout", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondaryAction)
                Button("Done", action: onDone)
                    .buttonStyle(.primaryAction)
            }
            .padding(AppSpacing.medium)
            .background(AppColors.surface)
        }
    }
}
