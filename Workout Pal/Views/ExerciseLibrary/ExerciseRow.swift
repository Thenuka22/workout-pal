import SwiftUI

struct ExerciseRow: View {
    let item: CatalogItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text(item.exercise.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer(minLength: 0)
                DifficultyPill(difficulty: item.difficulty)
            }
            if !item.exercise.primaryMuscles.isEmpty {
                Text(item.exercise.primaryMuscles.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
