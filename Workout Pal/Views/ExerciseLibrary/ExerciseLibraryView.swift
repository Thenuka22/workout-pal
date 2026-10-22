import SwiftUI

struct ExerciseLibraryView: View {
    @State private var model: ExerciseLibraryViewModel

    init(model: ExerciseLibraryViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        content
            .navigationTitle("Exercise library")
            .toolbarBackground(AppColors.surface, for: .navigationBar)
            .searchable(text: $model.searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isRefreshing)
                }
            }
            .task {
                await model.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.exercises.isEmpty {
            ScrollView {
                emptyCard
                    .padding(AppSpacing.medium)
            }
            .screenBackground()
        } else {
            List {
                if model.isRefreshing {
                    HStack(spacing: AppSpacing.small) {
                        ProgressView()
                        Text(model.statusText)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .plainRow()
                }
                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.warning)
                        .plainRow()
                }
                if model.filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                        .plainRow()
                } else {
                    ForEach(model.filteredExercises) { exercise in
                        NavigationLink(value: exercise) {
                            ExerciseRow(exercise: exercise)
                        }
                        .cardRow()
                    }
                    Text(model.attributionText)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .plainRow(top: AppSpacing.medium, bottom: AppSpacing.large)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .screenBackground()
        }
    }

    private var emptyCard: some View {
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
                Text("Download the exercise catalogue from wger to search exercises and build routines.")
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
    }

    private var filterMenu: some View {
        Menu {
            Menu("Muscle") {
                Picker("Muscle", selection: $model.selectedMuscle) {
                    Text("All muscles").tag(String?.none)
                    ForEach(model.muscleOptions, id: \.self) { muscle in
                        Text(muscle).tag(Optional(muscle))
                    }
                }
            }
            Menu("Equipment") {
                Picker("Equipment", selection: $model.selectedEquipment) {
                    Text("All equipment").tag(String?.none)
                    ForEach(model.equipmentOptions, id: \.self) { equipment in
                        Text(equipment).tag(Optional(equipment))
                    }
                }
            }
            if model.hasFilters {
                Button("Clear filters", role: .destructive) {
                    model.clearFilters()
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: model.hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView(model: AppContainer(inMemory: true).makeExerciseLibraryViewModel())
    }
}
