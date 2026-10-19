import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                if let url = exercise.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(AppColors.textSecondary)
                        default:
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(AppColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }

                if !exercise.category.isEmpty {
                    Text(exercise.category)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                detailCard(title: "Primary muscles", items: exercise.primaryMuscles)
                detailCard(title: "Secondary muscles", items: exercise.secondaryMuscles)
                detailCard(title: "Equipment", items: exercise.equipment)

                if !exercise.summary.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        SectionHeader(title: "Instructions")
                        Text(exercise.summary)
                            .font(.body)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    SectionHeader(title: "Attribution")
                    Text("Exercise data from wger.de.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                    if !exercise.license.attribution.isEmpty {
                        Text(exercise.license.attribution)
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let url = exercise.license.url {
                        Link("View licence", destination: url)
                            .font(.footnote)
                    }
                }
                .card()
            }
            .padding(AppSpacing.medium)
        }
        .screenBackground()
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailCard(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                SectionHeader(title: title)
                Text(items.joined(separator: ", "))
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .card()
        }
    }
}
