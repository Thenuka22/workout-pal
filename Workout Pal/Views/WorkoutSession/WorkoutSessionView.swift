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
                        .frame(width: 320)
                    Divider()
                    if let exercise = model.selectedExercise {
                        List {
                            setsSection(for: exercise)
                        }
                        .screenBackground()
                    } else {
                        ContentUnavailableView("No exercises", systemImage: "dumbbell")
                            .screenBackground()
                    }
                }
            } else {
                List {
                    summarySection
                    ForEach(model.session.exercises) { exercise in
                        setsSection(for: exercise)
                    }
                }
                .screenBackground()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let restEndsAt = model.restEndsAt {
                RestTimerBar(endsAt: restEndsAt) {
                    model.skipRest()
                }
            }
        }
        .navigationTitle(model.session.routineName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    isConfirmingFinish = true
                }
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog("Finish this workout?", isPresented: $isConfirmingFinish, titleVisibility: .visible) {
            Button("Finish workout") {
                model.finish()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("\(model.session.completedSetCount) of \(model.session.totalSetCount) sets are marked done.")
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

    private var summarySection: some View {
        Section {
            HStack {
                Label {
                    Text(model.session.startedAt, style: .timer)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "clock")
                }
                Spacer()
                Text("\(model.session.completedSetCount) of \(model.session.totalSetCount) sets")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(.subheadline)
        }
    }

    private var exerciseList: some View {
        List {
            summarySection
            Section("Exercises") {
                ForEach(model.session.exercises) { exercise in
                    Button {
                        model.selectedExerciseID = exercise.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text(exercise.exerciseName)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("\(exercise.completedSetCount) of \(exercise.sets.count) sets done")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer()
                            if exercise.completedSetCount == exercise.sets.count && !exercise.sets.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.success)
                            }
                        }
                    }
                    .listRowBackground(
                        exercise.id == model.selectedExercise?.id ? AppColors.accent.opacity(0.2) : nil
                    )
                }
            }
        }
        .screenBackground()
    }

    private func setsSection(for exercise: SessionExercise) -> some View {
        Section {
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                SetRow(
                    index: index,
                    set: set,
                    units: model.units,
                    onReps: { model.updateReps(exerciseID: exercise.id, setID: set.id, reps: $0) },
                    onLoad: { model.updateLoad(exerciseID: exercise.id, setID: set.id, load: $0) },
                    onToggle: { model.toggleCompletion(exerciseID: exercise.id, setID: set.id) }
                )
                .swipeActions {
                    Button("Remove", role: .destructive) {
                        model.removeSet(exerciseID: exercise.id, setID: set.id)
                    }
                }
            }
            Button {
                model.addSet(to: exercise.id)
            } label: {
                Label("Add set", systemImage: "plus")
            }
        } header: {
            HStack {
                Text(exercise.exerciseName)
                Spacer()
                if exercise.restSeconds > 0 {
                    Text("Rest \(exercise.restSeconds) s")
                }
            }
        }
    }
}
