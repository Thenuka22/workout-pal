import SwiftUI

struct RoutineDetailView: View {
    @Environment(\.dismiss) private var dismiss
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
        .navigationTitle("Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .toolbar {
            if !embedded && model.routine != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            model.isConfirmingDelete = true
                        } label: {
                            Label("Delete routine", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More options")
                }
            }
        }
        .confirmationDialog(
            "Delete \(model.routine?.name ?? "this routine")?",
            isPresented: $model.isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete routine", role: .destructive) {
                model.deleteRoutine()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Workouts you've already logged from it stay in your history.")
        }
        .alert("Could not delete routine", isPresented: $model.isShowingDeleteError) {
            Button("OK") {}
        } message: {
            Text(model.deleteErrorMessage ?? "")
        }
        .onChange(of: model.isDeleted) { _, isDeleted in
            if isDeleted {
                onRoutineUpdated()
                dismiss()
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
        .confirmationDialog(
            "You have a workout in progress",
            isPresented: $model.isAskingAboutActiveSession,
            titleVisibility: .visible
        ) {
            if let active = model.activeSession {
                Button("Resume \(active.routineName)") {
                    model.resumeActiveSession()
                }
                Button("Discard it and start new", role: .destructive) {
                    model.discardActiveSessionAndStart()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Finish or discard the current workout before starting another one.")
        }
        .alert("Could not start workout", isPresented: $model.isShowingStartError) {
            Button("OK") {}
        } message: {
            Text(model.startErrorMessage ?? "")
        }
        .task {
            await model.load()
        }
    }

    private func routineContent(_ routine: Routine) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                heroBlock(routine)
                HStack(spacing: AppSpacing.small) {
                    TagPill(text: "about \(routine.estimatedMinutes) min", symbolName: "clock")
                    TagPill(text: "\(routine.exercises.count) exercises", symbolName: "dumbbell")
                    TagPill(text: "\(routine.plannedSetCount) sets", symbolName: "checkmark.circle")
                }
                Text("Your session")
                    .cardTitle()
                    .padding(.top, AppSpacing.small)
                exerciseList(routine)
            }
            .padding(AppSpacing.medium)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .screenBackground()
        .safeAreaInset(edge: .bottom) {
            Button {
                model.startWorkout()
            } label: {
                Label("Start this workout", systemImage: "play.fill")
            }
            .buttonStyle(.primaryAction)
            .disabled(routine.exercises.isEmpty)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.surface)
        }
    }

    private func heroBlock(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top) {
                Text("Routine")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .foregroundStyle(AppColors.onAccent)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(AppColors.accent, in: Capsule())
                Spacer()
                if embedded {
                    Button("Edit") {
                        isEditing = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            Text(routine.name)
                .font(.title.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if !routine.notes.isEmpty {
                Text(routine.notes)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.medium)
        .photoCard(AppImages.shoulderPressWide, minHeight: 220)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.outline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func exerciseList(_ routine: Routine) -> some View {
        if routine.exercises.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("No exercises yet")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Edit the routine to add exercises from the library.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .card()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, item in
                    RoutineExerciseRow(index: index, item: item, units: model.units)
                        .padding(.vertical, AppSpacing.small)
                    if index < routine.exercises.count - 1 {
                        Divider()
                            .overlay(AppColors.outline)
                    }
                }
            }
            .card()
        }
    }

    private func routineEdited() {
        model.reload()
        onRoutineUpdated()
    }
}

struct RoutineExerciseRow: View {
    let index: Int
    let item: RoutineExercise
    let units: UnitPreference

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            NumberBadge(index: index)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(item.exerciseName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var detail: String {
        var parts = ["\(item.plannedSets) sets · \(item.plannedReps) reps", Formatting.load(item.plannedLoad, units: units)]
        if item.restSeconds > 0 {
            parts.append("rest \(item.restSeconds) s")
        }
        return parts.joined(separator: " · ")
    }
}
