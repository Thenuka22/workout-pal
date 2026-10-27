import SwiftUI

struct ExerciseDetailView: View {
    @Environment(AppContainer.self) private var container
    @State private var isAddingToRoutine = false
    let item: CatalogItem

    private var exercise: Exercise {
        item.exercise
    }

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

                HStack(spacing: AppSpacing.small) {
                    TagPill(text: item.area.title, symbolName: item.area.symbolName)
                    DifficultyPill(difficulty: item.difficulty)
                    Text("Estimated level")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                detailCard(title: "Primary muscles", items: exercise.primaryMuscles)
                detailCard(title: "Secondary muscles", items: exercise.secondaryMuscles)
                detailCard(title: "Equipment", items: exercise.equipment)

                if !exercise.summary.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Instructions").eyebrow()
                        Text(exercise.summary)
                            .font(.body)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Attribution").eyebrow()
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
        .safeAreaInset(edge: .bottom) {
            Button {
                isAddingToRoutine = true
            } label: {
                Label("Add to routine", systemImage: "plus")
            }
            .buttonStyle(.primaryAction)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.surface)
        }
        .sheet(isPresented: $isAddingToRoutine) {
            AddToRoutineSheet(model: container.makeAddToRoutineViewModel(exercise: exercise))
        }
    }

    @ViewBuilder
    private func detailCard(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title).eyebrow()
                Text(items.joined(separator: ", "))
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .card()
        }
    }
}
