import SwiftUI

struct ActivityDetailView: View {
    let activity: ActivitySession
    let units: UnitPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                ActivitySummaryCard(activity: activity, units: units)
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("About these numbers")
                        .eyebrow()
                    Text("Steps and distance were measured by your phone's motion sensors while the session was running. Paused time isn't counted and distance is an estimate.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .card()
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .navigationTitle(activity.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
    }
}
