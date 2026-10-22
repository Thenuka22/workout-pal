import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession
    let units: UnitPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Completed workout")
                        .eyebrow()
                    Text(session.routineName)
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(Formatting.dateTime(session.startedAt))
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    StatTile(
                        title: "Duration",
                        value: Formatting.minutes(fromSeconds: session.activeSeconds),
                        dotColor: AppColors.infoBlue
                    )
                    StatTile(
                        title: "Sets done",
                        value: "\(session.completedSetCount) of \(session.totalSetCount)",
                        dotColor: AppColors.infoOrange
                    )
                    StatTile(
                        title: "Volume",
                        value: Formatting.volume(kilograms: session.loadedVolumeKilograms, units: units),
                        dotColor: AppColors.infoPurple
                    )
                }
                ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseCard(index: index, exercise: exercise)
                }
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Notes")
                            .eyebrow()
                        Text(session.notes)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .card()
                }
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .navigationTitle("Workout details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
    }

    private func exerciseCard(index: Int, exercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                NumberBadge(index: index)
                Text(exercise.exerciseName)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(exercise.completedSetCount) of \(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            if exercise.sets.isEmpty {
                Text("No sets")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                    HStack {
                        Text("Set \(setIndex + 1)")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(set.reps) reps · \(Formatting.load(set.load, units: units))")
                            .foregroundStyle(AppColors.textPrimary)
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(set.isCompleted ? AppColors.accent : AppColors.textSecondary)
                            .accessibilityLabel(set.isCompleted ? "Done" : "Not done")
                    }
                    .font(.subheadline)
                }
            }
        }
        .card()
    }
}
