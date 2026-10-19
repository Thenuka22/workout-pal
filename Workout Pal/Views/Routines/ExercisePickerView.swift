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
            if model.isLoading || model.isRefreshing {
                ProgressView(model.statusText)
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
                    Text("Download the exercise catalogue to add exercises to a routine.")
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
                if model.filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                } else {
                    ForEach(model.filteredExercises) { exercise in
                        Button {
                            onPick(exercise)
                            dismiss()
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                    }
                }
            }
            .screenBackground()
        }
    }
}
