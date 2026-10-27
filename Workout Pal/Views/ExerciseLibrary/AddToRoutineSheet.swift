import SwiftUI

struct AddToRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: AddToRoutineViewModel

    init(model: AddToRoutineViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let message = model.savedMessage {
                    Section {
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .listRowBackground(AppColors.surfaceElevated)
                }
                Section {
                    if model.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if model.routines.isEmpty {
                        Text("You don't have any routines yet. Name one below to start it with this exercise.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        ForEach(model.routines) { routine in
                            routineRow(routine)
                        }
                    }
                } header: {
                    Text("Your routines")
                        .eyebrow()
                } footer: {
                    Text("It's added with 3 sets of 10 reps. Change them in the routine editor.")
                }
                .listRowBackground(AppColors.surfaceElevated)
                Section {
                    TextField("Routine name", text: $model.newRoutineName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            model.createRoutine()
                        }
                    Button {
                        model.createRoutine()
                    } label: {
                        Label("Create routine", systemImage: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .disabled(!model.canCreateRoutine)
                } header: {
                    Text("New routine")
                        .eyebrow()
                }
                .listRowBackground(AppColors.surfaceElevated)
            }
            .screenBackground()
            .navigationTitle("Add \(model.exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Could not update routine", isPresented: $model.isShowingError) {
                Button("OK") {}
            } message: {
                Text(model.errorMessage ?? "")
            }
            .task {
                await model.load()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func routineRow(_ routine: Routine) -> some View {
        let added = model.contains(routine)
        return Button {
            model.add(to: routine)
        } label: {
            HStack(spacing: AppSpacing.small) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(routine.exercises.count == 1 ? "1 exercise" : "\(routine.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(added ? AppColors.accent : AppColors.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.isSaving)
        .accessibilityValue(added ? "Already added" : "")
        .accessibilityHint(added ? "" : "Adds this exercise to the routine")
    }
}
