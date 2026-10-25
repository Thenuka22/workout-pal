import SwiftUI

struct CatalogFilterBar: View {
    let scopes: [LibraryScope]
    @Binding var scope: LibraryScope
    @Binding var difficulty: ExerciseDifficulty?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            ChipPicker(options: scopes, selection: $scope) { $0.title }
            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    Chip(title: "All levels", isSelected: difficulty == nil) {
                        difficulty = nil
                    }
                    ForEach(ExerciseDifficulty.allCases) { level in
                        Chip(title: level.title, isSelected: difficulty == level) {
                            difficulty = level
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct CatalogSectionHeader: View {
    let section: ExerciseSection

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: section.area.symbolName)
                .foregroundStyle(AppColors.accent)
                .accessibilityHidden(true)
            Text(section.area.title)
            Spacer()
            Text("\(section.items.count)")
        }
        .eyebrow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.area.title), \(section.items.count) exercises")
    }
}

struct DifficultyPill: View {
    let difficulty: ExerciseDifficulty

    var body: some View {
        Text(difficulty.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(difficulty == .beginner ? AppColors.onAccent : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch difficulty {
        case .beginner: AppColors.accent
        case .intermediate: AppColors.infoBlue.opacity(0.35)
        case .advanced: AppColors.infoOrange.opacity(0.45)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.medium) {
        CatalogFilterBar(
            scopes: [.forYou, .all, .area(.arms), .area(.abs)],
            scope: .constant(.forYou),
            difficulty: .constant(nil)
        )
        HStack {
            DifficultyPill(difficulty: .beginner)
            DifficultyPill(difficulty: .intermediate)
            DifficultyPill(difficulty: .advanced)
        }
    }
    .padding()
    .background(AppColors.surface)
}
