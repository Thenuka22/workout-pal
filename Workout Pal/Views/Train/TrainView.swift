import Foundation
import SwiftUI

struct TrainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: TrainViewModel
    @State private var isCreating = false
    @State private var isShowingLibrary = false
    @State private var selectedRoutineID: UUID?

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
                    subtitle: "Browse exercises from wger and add them to a routine.",
                    symbolName: "books.vertical.fill"
                )
            }
            .buttonStyle(.plain)
            .plainRow()
            NavigationLink(value: TrainRoute.activityTracker) {
                LinkRow(
                    title: "Walk & run",
                    subtitle: "Track steps, estimated distance and active time",
                    symbolName: "figure.walk",
                    isHighlighted: true
                )
                .card()
            }
            .buttonStyle(.plain)
            .plainRow()
            NavigationLink(value: TrainRoute.repCounter) {
                LinkRow(
                    title: "Camera rep counter",
                    subtitle: "Count squats and jumping jacks with on-device pose detection",
                    symbolName: "camera.viewfinder",
                    isHighlighted: true
                )
                .card()
            }
            .buttonStyle(.plain)
            .plainRow()
            Text("Your routines")
                .cardTitle()
                .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
            routineRows
            if let message = model.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                    .plainRow()
            }
        }
        .listStyle(.plain)
        .screenBackground()
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
