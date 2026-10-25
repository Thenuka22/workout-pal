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
            let sections = model.sections
            List {
                CatalogFilterBar(scopes: model.scopeOptions, scope: $model.scope, difficulty: $model.difficulty)
                    .plainRow()
                if sections.isEmpty {
                    ContentUnavailableView(
                        "No exercises match",
                        systemImage: "magnifyingglass",
                        description: Text("Try another body area, level or search.")
                    )
                    .plainRow()
                } else {
                    ForEach(sections) { section in
                        CatalogSectionHeader(section: section)
                            .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
                        ForEach(section.items) { item in
                            Button {
                                onPick(item.exercise)
                                dismiss()
                            } label: {
                                HStack {
                                    ExerciseRow(item: item)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppColors.accent)
                                        .accessibilityLabel("Add")
                                }
                            }
                            .cardRow()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .screenBackground()
        }
    }
}
