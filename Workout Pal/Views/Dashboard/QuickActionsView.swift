import SwiftUI

struct QuickActionsView: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Quick actions")
            Button {
                navigation.selection = .train
            } label: {
                Label("Start a workout", systemImage: "play.fill")
            }
            .buttonStyle(.primaryAction)
        }
        .card()
    }
}
