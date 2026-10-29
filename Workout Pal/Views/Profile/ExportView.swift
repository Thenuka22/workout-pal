import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExportViewModel

    init(model: ExportViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Save your history as CSV files to open in Numbers, Excel or Google Sheets. Nothing is uploaded. You choose where the files go.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .listRowBackground(AppColors.surfaceElevated)
                if model.hasData {
                    Section {
                        if let file = model.workoutsFile {
                            ShareLink(item: file, preview: SharePreview(file.fileName)) {
                                LinkRow(title: "Workouts", subtitle: model.workoutsSummary, symbolName: "dumbbell.fill")
                            }
                        }
                        if let file = model.activitiesFile {
                            ShareLink(item: file, preview: SharePreview(file.fileName)) {
                                LinkRow(title: "Walks and runs", subtitle: model.activitiesSummary, symbolName: "figure.walk")
                            }
                        }
                    } footer: {
                        Text("Loads use your unit setting. Distances are estimates from your iPhone's motion sensors.")
                    }
                    .listRowBackground(AppColors.surfaceElevated)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .overlay {
                if model.isLoading {
                    ProgressView()
                } else if let message = model.errorMessage {
                    ContentUnavailableView("Could not read your history", systemImage: "exclamationmark.triangle", description: Text(message))
                } else if !model.hasData {
                    ContentUnavailableView(
                        "Nothing to export yet",
                        systemImage: "tray",
                        description: Text("Finish a workout, walk or run first.")
                    )
                }
            }
            .navigationTitle("Export your data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await model.load()
            }
        }
    }
}
