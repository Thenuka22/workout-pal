import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: WorkoutSessionViewModel
    @State private var isConfirmingFinish = false

    init(model: WorkoutSessionViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
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
                .screenBackground()
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationTitle(model.session.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .confirmationDialog("Finish this workout?", isPresented: $isConfirmingFinish, titleVisibility: .visible) {
            Button("Finish workout") {
                model.finish()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("\(model.progressText) are marked done.")
        }
        .alert("Could not save workout", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: model.isFinished) { _, isFinished in
            if isFinished {
                dismiss()
            }
        }
        .onAppear {
            model.start()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Elapsed")
                    .eyebrow()
                Spacer()
                Text(model.progressText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(model.session.startedAt, style: .timer)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)
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
                            Text("\(exercise.completedSetCount) of \(exercise.sets.count) sets done")
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
                        onReps: { model.updateReps(exerciseID: exercise.id, setID: set.id, reps: $0) },
                        onLoad: { model.updateLoad(exerciseID: exercise.id, setID: set.id, load: $0) },
                        onToggle: { model.toggleCompletion(exerciseID: exercise.id, setID: set.id) },
                        onRemove: { model.removeSet(exerciseID: exercise.id, setID: set.id) }
                    )
                }
            }
            Button {
                model.addSet(to: exercise.id)
            } label: {
                Label("Add set", systemImage: "plus")
            }
            .buttonStyle(.secondaryAction)
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
            Button {
                isConfirmingFinish = true
            } label: {
                Label("Finish workout", systemImage: "flag.checkered")
            }
            .buttonStyle(.primaryAction)
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
        var parts = ["\(exercise.completedSetCount) of \(exercise.sets.count) sets done"]
        if exercise.restSeconds > 0 {
            parts.append("rest \(exercise.restSeconds) s")
        }
        return parts.joined(separator: " · ")
    }
}
