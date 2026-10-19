import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(exercise.name)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    private var subtitle: String {
        var parts: [String] = []
        if !exercise.category.isEmpty {
            parts.append(exercise.category)
        }
        if !exercise.primaryMuscles.isEmpty {
            parts.append(exercise.primaryMuscles.joined(separator: ", "))
        }
        return parts.joined(separator: " · ")
    }
}
