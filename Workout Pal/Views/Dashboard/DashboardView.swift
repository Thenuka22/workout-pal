import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: DashboardViewModel
    @State private var isConfirmingDiscard = false

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
                            resumeCard
                            WeeklyProgressCard(summary: model.summary)
                            QuickActionsView()
                        }
                        RecentWorkoutCard(session: model.recentSession)
                    }
                } else {
                    VStack(spacing: AppSpacing.medium) {
                        resumeCard
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
        .navigationDestination(item: $model.resumingSession) { session in
            WorkoutSessionView(model: container.makeWorkoutSessionViewModel(session: session))
        }
        .confirmationDialog("Discard this workout?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("Discard workout", role: .destructive) {
                model.discardActiveSession()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("The sets you logged in this workout will be deleted.")
        }
        .task {
            await model.load()
        }
        .refreshable {
            await model.load()
        }
    }

    @ViewBuilder
    private var resumeCard: some View {
        if let active = model.activeSession {
            ResumeSessionCard(
                session: active,
                onResume: { model.resumeActiveSession() },
                onDiscard: { isConfirmingDiscard = true }
            )
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return NavigationStack {
        DashboardView(model: container.makeDashboardViewModel())
    }
    .environment(container)
    .environment(AppNavigation())
}
