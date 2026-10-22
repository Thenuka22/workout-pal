import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExerciseLibraryViewModel
    private let onPick: (Exercise) -> Void

    init(model: ExerciseLibraryViewModel, onPick: @escaping (Exercise) -> Void) {
        _model = State(initialValue: model)
        self.onPick = onPick
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add exercise")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppColors.surface, for: .navigationBar)
                .searchable(text: $model.searchText, prompt: "Search exercises")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .task {
                    await model.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.exercises.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Image(systemName: "books.vertical.fill")
                        .font(.largeTitle)
                        .foregroundStyle(AppColors.accent)
                    if model.isLoading || model.isRefreshing {
                        Text("Downloading the catalogue")
                            .cardTitle()
                        HStack(spacing: AppSpacing.small) {
                            ProgressView()
                            Text(model.statusText)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    } else if let message = model.errorMessage {
                        Text("Could not download exercises")
                            .cardTitle()
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        Button("Try again") {
                            model.refresh()
                        }
                        .buttonStyle(.primaryAction)
                    } else {
                        Text("No exercises yet")
                            .cardTitle()
                        Text("Download the exercise catalogue to add exercises to a routine.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        Button {
                            model.refresh()
                        } label: {
                            Label("Download catalogue", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.primaryAction)
                    }
                }
                .card()
                .padding(AppSpacing.medium)
            }
            .screenBackground()
        } else {
            List {
                if model.filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                        .plainRow()
                } else {
                    ForEach(model.filteredExercises) { exercise in
                        Button {
                            onPick(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                ExerciseRow(exercise: exercise)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                        .cardRow()
                    }
                }
            }
            .listStyle(.plain)
            .screenBackground()
        }
    }
}
