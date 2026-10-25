import Foundation
import SwiftUI

struct TrainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: TrainViewModel
    @State private var isCreating = false
    @State private var isShowingLibrary = false
    @State private var selectedRoutineID: UUID?
    @State private var showsStarterPlans = false

    init(model: TrainViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    routineList
                        .frame(width: 380)
                    Divider()
                    detailPane
                }
            } else {
                routineList
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isCreating, onDismiss: { model.reload() }) {
            RoutineEditorView(model: container.makeRoutineEditorViewModel(routine: nil))
        }
        .navigationDestination(for: TrainRoute.self) { route in
            TrainRouteView(route: route)
        }
        .navigationDestination(isPresented: $isShowingLibrary) {
            ExerciseLibraryView(model: container.makeExerciseLibraryViewModel())
        }
        .alert("Starter plans", isPresented: $model.isShowingStarterMessage) {
            Button("OK") {}
        } message: {
            Text(model.starterMessage ?? "")
        }
        .task {
            await model.load()
        }
    }

    private var routineList: some View {
        List {
            ScreenHeader(title: "Move", subtitle: "Pick a routine for today.") {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(AppColors.onAccent)
                        .frame(width: 44, height: 44)
                        .background(AppColors.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New routine")
            }
            .plainRow(top: 0, bottom: AppSpacing.small, horizontal: 0)
            SearchField(text: $model.searchText, prompt: "Search routines")
                .plainRow()
            Button {
                isShowingLibrary = true
            } label: {
                HeroCard(
                    eyebrow: "Explore",
                    title: "Exercise library",
                    subtitle: "Browse exercises by body area and level, then add them to a routine.",
                    symbolName: "books.vertical.fill",
                    imageName: AppImages.focusedStrengthWide
                )
            }
            .buttonStyle(.plain)
            .plainRow()
            HStack(spacing: AppSpacing.small) {
                NavigationLink(value: TrainRoute.activityTracker) {
                    PhotoTile(
                        title: "Walk & run",
                        subtitle: "Steps, estimated distance and time",
                        symbolName: "figure.walk",
                        imageName: AppImages.dawnJogWide
                    )
                }
                NavigationLink(value: TrainRoute.repCounter) {
                    PhotoTile(
                        title: "Count reps",
                        subtitle: "Squats and jumping jacks with the camera",
                        symbolName: "camera.viewfinder",
                        imageName: AppImages.controlledSquatWide
                    )
                }
            }
            .buttonStyle(.plain)
            .plainRow()
            if !model.isLoading && model.routines.isEmpty {
                Text("Starter plans")
                    .cardTitle()
                    .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
                starterPlanRows
            }
            Text("Your routines")
                .cardTitle()
                .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
            routineRows
            if !model.routines.isEmpty {
                Button {
                    showsStarterPlans.toggle()
                } label: {
                    LinkRow(
                        title: "Starter plans",
                        subtitle: "Ready-made routines for each level",
                        symbolName: "sparkles",
                        value: showsStarterPlans ? "Hide" : nil
                    )
                    .card()
                }
                .buttonStyle(.plain)
                .plainRow(top: AppSpacing.medium)
                if showsStarterPlans {
                    starterPlanRows
                }
            }
            if let message = model.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                    .plainRow()
            }
        }
        .listStyle(.plain)
        .screenBackground()
    }

    private var starterPlanRows: some View {
        ForEach(model.starterLevels) { level in
            Button {
                model.addStarterRoutines(level: level)
            } label: {
                LinkRow(
                    title: "\(level.title) plan",
                    subtitle: model.starterSummary(for: level),
                    symbolName: level.planSymbolName,
                    value: level == model.suggestedLevel ? "For you" : nil,
                    isHighlighted: level == model.suggestedLevel
                )
                .card()
            }
            .buttonStyle(.plain)
            .disabled(model.isAddingStarter)
            .accessibilityHint("Adds the \(level.title.lowercased()) routines to your list")
            .plainRow()
        }
    }

    @ViewBuilder
    private var routineRows: some View {
        if model.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .plainRow()
        } else if model.routines.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("No routines yet")
                    .cardTitle()
                Text("Create a routine with the exercises you want to log.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                Button {
                    isCreating = true
                } label: {
                    Label("Create a routine", systemImage: "plus")
                }
                .buttonStyle(.primaryAction)
            }
            .card()
            .plainRow()
        } else if model.filteredRoutines.isEmpty {
            Text("No routines match \"\(model.searchText)\".")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .plainRow()
        } else {
            ForEach(Array(model.filteredRoutines.enumerated()), id: \.element.id) { index, routine in
                if horizontalSizeClass == .regular {
                    Button {
                        selectedRoutineID = routine.id
                    } label: {
                        RoutineRow(index: index, routine: routine)
                    }
                    .cardRow(isSelected: routine.id == selectedRoutineID)
                } else {
                    NavigationLink(value: TrainRoute.routine(routine.id)) {
                        RoutineRow(index: index, routine: routine)
                    }
                    .cardRow()
                }
            }
            .onDelete { offsets in
                model.delete(at: offsets)
            }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedRoutineID {
            RoutineDetailView(
                model: container.makeRoutineDetailViewModel(routineID: selectedRoutineID),
                embedded: true,
                onRoutineUpdated: { model.reload() }
            )
            .id(selectedRoutineID)
        } else {
            ContentUnavailableView(
                "Select a routine",
                systemImage: "list.bullet.rectangle",
                description: Text("Choose a routine to see its exercises, or create a new one.")
            )
            .screenBackground()
        }
    }
}

struct RoutineRow: View {
    let index: Int
    let routine: Routine

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            NumberBadge(index: index)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(routine.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(routine.exercises.count) exercises · about \(routine.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return NavigationStack {
        TrainView(model: container.makeTrainViewModel())
    }
    .environment(container)
}
