import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @Environment(AppNavigation.self) private var navigation
    @State private var model: DashboardViewModel
    @State private var isConfirmingDiscard = false

    init(model: DashboardViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                ScreenHeader(title: model.title, overline: model.greeting) {
                    Button {
                        navigation.selection = .profile
                    } label: {
                        AvatarBadge(initial: model.initial)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profile")
                }
                Group {
                    if let message = model.errorMessage {
                        ErrorStateView(title: "Could not load your workouts", message: message) {
                            model.retry()
                        }
                    } else if horizontalSizeClass == .regular {
                        twoColumns
                    } else {
                        singleColumn
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
            }
            .padding(.bottom, AppSpacing.large)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .navigationDestination(item: $model.resumingSession) { session in
            WorkoutSessionView(model: container.makeWorkoutSessionViewModel(session: session))
        }
        .navigationDestination(for: TrainRoute.self) { route in
            TrainRouteView(route: route)
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

    private var singleColumn: some View {
        VStack(spacing: AppSpacing.medium) {
            resumeCard
            activityResumeCard
            WeeklyProgressCard(summary: model.summary, statusText: model.weekStatusText, showsWeekdays: false, streak: model.weekStreak)
            todayPlanCard
            QuickActionsRow()
            MovementCard(summary: model.summary)
            RecentWorkoutCard(session: model.recentSession)
        }
    }

    private var twoColumns: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            VStack(spacing: AppSpacing.medium) {
                resumeCard
                activityResumeCard
                WeeklyProgressCard(summary: model.summary, statusText: model.weekStatusText, showsWeekdays: true, streak: model.weekStreak)
                todayPlanCard
                QuickActionsRow()
            }
            VStack(spacing: AppSpacing.medium) {
                MovementCard(summary: model.summary)
                RecentWorkoutCard(session: model.recentSession)
            }
            .frame(width: 320)
        }
    }

    @ViewBuilder
    private var activityResumeCard: some View {
        if let activity = model.activeActivity {
            NavigationLink(value: TrainRoute.activityTracker) {
                LinkRow(
                    title: "\(activity.kind.title) in progress",
                    subtitle: "Started \(Formatting.dateTime(activity.startedAt))",
                    symbolName: activity.kind.symbolName,
                    value: activity.isPaused ? "Paused" : "Open",
                    isHighlighted: true
                )
                .card()
            }
            .buttonStyle(.plain)
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

    @ViewBuilder
    private var todayPlanCard: some View {
        if let routine = model.suggestedRoutine {
            NavigationLink(value: TrainRoute.routine(routine.id)) {
                HeroCard(
                    eyebrow: "Today's plan",
                    title: routine.name,
                    subtitle: "\(routine.exercises.count) exercises · about \(routine.estimatedMinutes) min",
                    symbolName: "dumbbell.fill"
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                navigation.selection = .train
            } label: {
                HeroCard(
                    eyebrow: "Get started",
                    title: "Create your first routine",
                    subtitle: "Pick exercises from the library and plan your sets.",
                    symbolName: "plus.circle.fill"
                )
            }
            .buttonStyle(.plain)
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
