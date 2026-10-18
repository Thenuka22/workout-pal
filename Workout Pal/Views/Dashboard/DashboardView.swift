import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: DashboardViewModel

    init(model: DashboardViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            Group {
                if let message = model.errorMessage {
                    ErrorStateView(title: "Could not load your workouts", message: message) {
                        model.retry()
                    }
                } else if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        VStack(spacing: AppSpacing.medium) {
                            WeeklyProgressCard(summary: model.summary)
                            QuickActionsView()
                        }
                        RecentWorkoutCard(session: model.recentSession)
                    }
                } else {
                    VStack(spacing: AppSpacing.medium) {
                        WeeklyProgressCard(summary: model.summary)
                        RecentWorkoutCard(session: model.recentSession)
                        QuickActionsView()
                    }
                }
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .navigationTitle("Home")
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .task {
            await model.load()
        }
        .refreshable {
            await model.load()
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView(model: AppContainer(inMemory: true).makeDashboardViewModel())
    }
    .environment(AppNavigation())
}
