import Foundation
import SwiftUI

struct WorkoutSessionView: View {
    private struct CameraTarget: Identifiable {
        let exerciseID: UUID
        let exercise: CameraExercise

        var id: UUID { exerciseID }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: WorkoutSessionViewModel
    @State private var isConfirmingFinish = false
    @State private var cameraTarget: CameraTarget?
    @FocusState private var focusedSet: UUID?

    init(model: WorkoutSessionViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        if let summary = model.finishSummary {
            WorkoutSummaryView(summary: summary, units: model.units) {
                dismiss()
            }
            .navigationTitle("Workout complete")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        } else {
            workoutContent
        }
    }

    private var workoutContent: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    exerciseList
                        .frame(width: 340)
                    Divider()
                    if let exercise = model.selectedExercise {
                        ScrollView {
                            exerciseCard(exercise, index: index(of: exercise))
                                .padding(AppSpacing.medium)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .screenBackground()
                    } else {
                        ContentUnavailableView("No exercises", systemImage: "dumbbell")
                            .screenBackground()
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        summaryCard
                        ForEach(Array(model.session.exercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseCard(exercise, index: index)
                        }
                    }
                    .padding(AppSpacing.medium)
                }
                .scrollDismissesKeyboard(.interactively)
                .screenBackground()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedSet = nil
                }
                .fontWeight(.semibold)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationTitle(model.session.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .confirmationDialog(
            model.hasCompletedSets ? "Finish this workout?" : "No sets done yet",
            isPresented: $isConfirmingFinish,
            titleVisibility: .visible
        ) {
            if model.hasCompletedSets {
                Button("Finish workout") {
                    model.finish()
                }
            } else {
                Button("Discard workout", role: .destructive) {
                    model.discard()
                }
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            if model.hasCompletedSets {
                Text("\(model.progressText) are marked done.")
            } else {
                Text("Mark at least one set as done to save this workout, or discard it.")
            }
        }
        .alert("Still training?", isPresented: $model.isAskingAboutStaleSession) {
            if let time = model.lastSetTimeText {
                Button("Finish at \(time)") {
                    model.finishAtLastSet()
                }
            } else {
                Button("Discard workout", role: .destructive) {
                    model.discard()
                }
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text(model.staleMessage)
        }
        .onChange(of: model.isDiscarded) { _, isDiscarded in
            if isDiscarded {
                dismiss()
            }
        }
        .alert("Could not save workout", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .sheet(item: $cameraTarget) { target in
            NavigationStack {
                RepCounterView(
                    model: container.makeRepCounterViewModel(exercise: target.exercise, mode: .workoutSet)
                ) { reps in
                    model.addCameraSet(exerciseID: target.exerciseID, reps: reps)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            cameraTarget = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            model.start()
        }
        .onDisappear {
            model.disappear()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.isPaused ? "Paused" : "Elapsed")
                    .eyebrow()
                Spacer()
                Text(model.progressText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = Formatting.elapsed(seconds: model.elapsedSeconds(at: context.date))
                Text(elapsed)
                    .accessibilityLabel(model.isPaused ? "Paused at \(elapsed)" : "Elapsed time \(elapsed)")
                    .metric(size: 40)
                    .foregroundStyle(model.isPaused ? AppColors.textSecondary : AppColors.textPrimary)
            }
            ProgressView(
                value: Double(model.session.completedSetCount),
                total: Double(max(model.session.totalSetCount, 1))
            )
            .tint(AppColors.accent)
        }
        .card()
    }

    private var exerciseList: some View {
        List {
            summaryCard
                .plainRow()
            ForEach(Array(model.session.exercises.enumerated()), id: \.element.id) { index, exercise in
                Button {
                    model.selectedExerciseID = exercise.id
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        NumberBadge(index: index)
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(exercise.exerciseName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(exercise.completedSetCount) of \(Formatting.count(exercise.sets.count, "set")) done")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        if isComplete(exercise) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .cardRow(isSelected: exercise.id == model.selectedExercise?.id)
            }
        }
        .listStyle(.plain)
        .screenBackground()
    }

    private func exerciseCard(_ exercise: SessionExercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                NumberBadge(index: index)
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(detail(for: exercise))
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                if isComplete(exercise) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.accent)
                }
            }
            VStack(spacing: AppSpacing.small) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                    SetRow(
                        index: setIndex,
                        set: set,
                        units: model.units,
                        focusedSet: $focusedSet,
                        onReps: { model.updateReps(exerciseID: exercise.id, setID: set.id, reps: $0) },
                        onLoad: { model.updateLoad(exerciseID: exercise.id, setID: set.id, load: $0) },
                        onBodyweight: { model.setBodyweight(exerciseID: exercise.id, setID: set.id, isOn: $0) },
                        onToggle: { model.toggleCompletion(exerciseID: exercise.id, setID: set.id) },
                        onRemove: { model.removeSet(exerciseID: exercise.id, setID: set.id) }
                    )
                }
            }
            HStack(spacing: AppSpacing.small) {
                Button {
                    model.addSet(to: exercise.id)
                } label: {
                    Label("Add set", systemImage: "plus")
                }
                .buttonStyle(.secondaryAction)
                if let cameraExercise = model.cameraExercise(for: exercise) {
                    Button {
                        cameraTarget = CameraTarget(exerciseID: exercise.id, exercise: cameraExercise)
                    } label: {
                        Label("Count reps", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.secondaryAction)
                }
            }
        }
        .card()
    }

    private var bottomBar: some View {
        VStack(spacing: AppSpacing.small) {
            if let start = model.restStartedAt, let end = model.restEndsAt {
                RestTimerBar(startedAt: start, endsAt: end, nextExerciseName: model.nextExerciseName) {
                    model.skipRest()
                }
            }
            HStack(spacing: AppSpacing.small) {
                Button {
                    if model.isPaused {
                        model.resume()
                    } else {
                        model.pause()
                    }
                } label: {
                    Label(model.isPaused ? "Resume" : "Pause", systemImage: model.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.secondaryAction)
                Button {
                    isConfirmingFinish = true
                } label: {
                    Label("Finish", systemImage: "flag.checkered")
                }
                .buttonStyle(.primaryAction)
                .disabled(model.isFinishing)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.surface)
    }

    private func index(of exercise: SessionExercise) -> Int {
        model.session.exercises.firstIndex { $0.id == exercise.id } ?? 0
    }

    private func isComplete(_ exercise: SessionExercise) -> Bool {
        !exercise.sets.isEmpty && exercise.completedSetCount == exercise.sets.count
    }

    private func detail(for exercise: SessionExercise) -> String {
        var parts = ["\(exercise.completedSetCount) of \(Formatting.count(exercise.sets.count, "set")) done"]
        if exercise.restSeconds > 0 {
            parts.append("rest \(exercise.restSeconds) s")
        }
        return parts.joined(separator: " · ")
    }
}
