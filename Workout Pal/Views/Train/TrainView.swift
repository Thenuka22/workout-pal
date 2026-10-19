import Foundation
import SwiftUI

struct TrainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: TrainViewModel
    @State private var isCreating = false
    @State private var selectedRoutineID: UUID?

    init(model: TrainViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    routineList
                        .frame(width: 360)
                    Divider()
                    detailPane
                }
            } else {
                routineList
            }
        }
        .navigationTitle("Train")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreating = true
                } label: {
                    Label("New routine", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreating, onDismiss: { model.reload() }) {
            RoutineEditorView(model: container.makeRoutineEditorViewModel(routine: nil))
        }
        .navigationDestination(for: TrainRoute.self) { route in
            switch route {
            case .routine(let id):
                RoutineDetailView(model: container.makeRoutineDetailViewModel(routineID: id), embedded: false)
            }
        }
        .task {
            await model.load()
        }
    }

    private var routineList: some View {
        List {
            Section("Routines") {
                if model.isLoading {
                    ProgressView()
                } else if model.routines.isEmpty {
                    Text("No routines yet. Tap + to create one.")
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ForEach(model.routines) { routine in
                        if horizontalSizeClass == .regular {
                            Button {
                                selectedRoutineID = routine.id
                            } label: {
                                RoutineRow(routine: routine)
                            }
                            .listRowBackground(
                                routine.id == selectedRoutineID ? AppColors.accent.opacity(0.2) : nil
                            )
                        } else {
                            NavigationLink(value: TrainRoute.routine(routine.id)) {
                                RoutineRow(routine: routine)
                            }
                        }
                    }
                    .onDelete { offsets in
                        model.delete(at: offsets)
                    }
                }
            }
            if let message = model.errorMessage {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.warning)
                }
            }
            Section("Library") {
                NavigationLink {
                    ExerciseLibraryView(model: container.makeExerciseLibraryViewModel())
                } label: {
                    Label("Exercise library", systemImage: "books.vertical.fill")
                }
            }
        }
        .screenBackground()
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedRoutineID {
            RoutineDetailView(
                model: container.makeRoutineDetailViewModel(routineID: selectedRoutineID),
                embedded: true,
                onRoutineUpdated: { model.reload() }
            )
            .id(selectedRoutineID)
        } else {
            ContentUnavailableView(
                "Select a routine",
                systemImage: "list.bullet.rectangle",
                description: Text("Choose a routine to see its exercises, or create a new one.")
            )
            .screenBackground()
        }
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(routine.name)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            Text("\(routine.exercises.count) exercises")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return NavigationStack {
        TrainView(model: container.makeTrainViewModel())
    }
    .environment(container)
}
