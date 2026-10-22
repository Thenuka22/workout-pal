import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text(exercise.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer(minLength: 0)
                if !exercise.category.isEmpty {
                    TagPill(text: exercise.category)
                }
            }
            if !exercise.primaryMuscles.isEmpty {
                Text(exercise.primaryMuscles.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}
