import SwiftUI

struct ActivityDetailView<Footer: View>: View {
    let activity: ActivitySession
    let units: UnitPreference
    let footer: Footer

    init(activity: ActivitySession, units: UnitPreference, @ViewBuilder footer: () -> Footer) {
        self.activity = activity
        self.units = units
        self.footer = footer()
    }

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
                footer
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .navigationTitle(activity.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
    }
}

extension ActivityDetailView where Footer == EmptyView {
    init(activity: ActivitySession, units: UnitPreference) {
        self.init(activity: activity, units: units) {
            EmptyView()
        }
    }
}
