import SwiftUI

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    @State private var model: RoutineEditorViewModel
    @State private var isPickingExercise = false
    @State private var isConfirmingCancel = false
    private let reorderTip = ReorderExercisesTip()

    init(model: RoutineEditorViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $model.draft.name)
                    TextField("Notes", text: $model.draft.notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Routine")
                        .eyebrow()
                }
                .listRowBackground(AppColors.surfaceElevated)
                Section {
                    ForEach($model.draft.exercises) { $item in
                        NavigationLink {
                            RoutineExerciseEditor(item: $item, units: model.units)
                        } label: {
                            RoutineExerciseRow(
                                index: model.draft.exercises.firstIndex { $0.id == item.id } ?? 0,
                                item: item,
                                units: model.units
                            )
                        }
                    }
                    .onMove { source, destination in
                        reorderTip.invalidate(reason: .actionPerformed)
                        model.moveExercises(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        model.removeExercises(at: offsets)
                    }
                    if model.draft.exercises.count >= 2 {
                        TipView(reorderTip)
                            .tipBackground(AppColors.surface)
                    }
                    Button {
                        isPickingExercise = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                            .font(.body.weight(.semibold))
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                            .eyebrow()
                        Spacer()
                        if !model.draft.exercises.isEmpty {
                            EditButton()
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Tap an exercise to change its sets, reps, load and rest. Use Edit to reorder or remove.")
                }
                .listRowBackground(AppColors.surfaceElevated)
            }
            .screenBackground()
            .navigationTitle(model.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if model.hasChanges {
                            isConfirmingCancel = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!model.canSave)
                }
            }
            .sheet(isPresented: $isPickingExercise) {
                ExercisePickerView(model: container.makeExerciseLibraryViewModel()) { exercise in
                    model.add(exercise)
                }
            }
            .confirmationDialog("Discard your changes?", isPresented: $isConfirmingCancel, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Could not save routine", isPresented: $model.isShowingError) {
                Button("OK") {}
            } message: {
                Text(model.errorMessage ?? "")
            }
            .onChange(of: model.isSaved) { _, isSaved in
                if isSaved {
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(model.hasChanges)
    }
}
