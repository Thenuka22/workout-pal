import SwiftUI

struct ExerciseLibraryView: View {
    @State private var model: ExerciseLibraryViewModel

    init(model: ExerciseLibraryViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        content
            .navigationTitle("Exercise library")
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
            if model.isLoading || model.isRefreshing {
                VStack(spacing: AppSpacing.medium) {
                    ProgressView()
                    Text(model.statusText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .screenBackground()
            } else if let message = model.errorMessage {
                ErrorStateView(title: "Could not download exercises", message: message) {
                    model.refresh()
                }
                .screenBackground()
            } else {
                ContentUnavailableView {
                    Label("No exercises yet", systemImage: "books.vertical")
                } description: {
                    Text("Download the exercise catalogue from wger to search exercises and build routines.")
                } actions: {
                    Button("Download catalogue") {
                        model.refresh()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .screenBackground()
            }
        } else {
            List {
                if model.isRefreshing {
                    Section {
                        HStack(spacing: AppSpacing.small) {
                            ProgressView()
                            Text(model.statusText)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                if let message = model.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.warning)
                    }
                }
                if model.filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                } else {
                    Section {
                        ForEach(model.filteredExercises) { exercise in
                            NavigationLink(value: exercise) {
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    } footer: {
                        Text(model.attributionText)
                    }
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .screenBackground()
        }
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
