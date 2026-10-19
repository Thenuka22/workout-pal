import SwiftUI

struct RoutineDetailView: View {
    @Environment(AppContainer.self) private var container
    @State private var model: RoutineDetailViewModel
    @State private var isEditing = false
    private let embedded: Bool
    private let onRoutineUpdated: () -> Void

    init(model: RoutineDetailViewModel, embedded: Bool, onRoutineUpdated: @escaping () -> Void = {}) {
        _model = State(initialValue: model)
        self.embedded = embedded
        self.onRoutineUpdated = onRoutineUpdated
    }

    var body: some View {
        Group {
            if let routine = model.routine {
                routineContent(routine)
            } else if model.isLoading {
                ProgressView()
                    .screenBackground()
            } else if let message = model.errorMessage {
                ErrorStateView(title: "Could not load routine", message: message) {
                    model.reload()
                }
                .screenBackground()
            } else {
                ContentUnavailableView(
                    "Routine not found",
                    systemImage: "questionmark.folder",
                    description: Text("This routine was removed.")
                )
                .screenBackground()
            }
        }
        .sheet(isPresented: $isEditing, onDismiss: { routineEdited() }) {
            if let routine = model.routine {
                RoutineEditorView(model: container.makeRoutineEditorViewModel(routine: routine))
            }
        }
        .navigationDestination(item: $model.startedSession) { session in
            WorkoutSessionView(model: container.makeWorkoutSessionViewModel(session: session))
        }
        .task {
            await model.load()
        }
    }

    private func routineContent(_ routine: Routine) -> some View {
        List {
            if embedded {
                Section {
                    HStack {
                        Text(routine.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            if !routine.notes.isEmpty {
                Section("Notes") {
                    Text(routine.notes)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            Section("Exercises") {
                if routine.exercises.isEmpty {
                    Text("No exercises yet. Edit the routine to add some.")
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ForEach(routine.exercises) { item in
                        RoutineExerciseRow(item: item, units: model.units)
                    }
                }
            }
            Section {
                Button {
                    model.startWorkout()
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                }
                .buttonStyle(.primaryAction)
                .disabled(routine.exercises.isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .screenBackground()
        .navigationTitle(embedded ? "Train" : routine.name)
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
    }

    private func routineEdited() {
        model.reload()
        onRoutineUpdated()
    }
}

struct RoutineExerciseRow: View {
    let item: RoutineExercise
    let units: UnitPreference

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(item.exerciseName)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    private var detail: String {
        var parts = ["\(item.plannedSets) × \(item.plannedReps)", Formatting.load(item.plannedLoad, units: units)]
        if item.restSeconds > 0 {
            parts.append("Rest \(item.restSeconds) s")
        }
        return parts.joined(separator: " · ")
    }
}
