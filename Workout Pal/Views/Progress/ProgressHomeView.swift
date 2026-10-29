import SwiftUI

struct ProgressHomeView: View {
    private enum Panel: String, CaseIterable, Identifiable {
        case charts = "Charts"
        case history = "History"

        var id: String { rawValue }
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppContainer.self) private var container
    @State private var model: ProgressHomeViewModel
    @State private var panel: Panel = .charts
    @State private var selectedEntry: HistoryEntry?

    init(model: ProgressHomeViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Your progress", subtitle: model.subtitle)
            if horizontalSizeClass != .regular {
                ChipPicker(options: Panel.allCases, selection: $panel) { $0.rawValue }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.small)
            }
            content
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: HistoryEntry.self) { entry in
            HistoryEntryDetailView(
                model: container.makeHistoryDetailViewModel(entry: entry),
                onChange: { model.retry() },
                onDeleted: { model.retry() }
            )
        }
        .navigationDestination(for: ExerciseOption.self) { option in
            ExerciseHistoryView(model: container.makeExerciseHistoryViewModel(exerciseID: option.id, name: option.name))
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = model.errorMessage {
            ErrorStateView(title: "Could not load your history", message: message) {
                model.retry()
            }
        } else if !model.hasHistory && !model.isLoading {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    ContentUnavailableView(
                        "Nothing logged yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Finish a workout, walk or run to see your history and charts.")
                    )
                    HealthTodayCard(
                        state: model.healthState,
                        todayActiveMinutes: model.todayActiveMinutes,
                        units: model.units,
                        onConnect: { model.connectHealth() },
                        onRefresh: { model.refreshHealth() }
                    )
                }
                .padding(AppSpacing.medium)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .task {
                await model.loadHealth()
            }
        } else if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedEntry: $selectedEntry)
                    .frame(width: 380)
                Divider()
                if let selectedEntry {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("Show charts") {
                                self.selectedEntry = nil
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.top, AppSpacing.small)
                        HistoryEntryDetailView(
                            model: container.makeHistoryDetailViewModel(entry: selectedEntry),
                            isEmbedded: true,
                            onChange: { model.retry() },
                            onDeleted: {
                                self.selectedEntry = nil
                                model.retry()
                            }
                        )
                        .id(selectedEntry.id)
                    }
                } else {
                    ProgressChartsView(model: model)
                }
            }
        } else {
            switch panel {
            case .charts:
                ProgressChartsView(model: model)
            case .history:
                WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedEntry: nil)
            }
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return NavigationStack {
        ProgressHomeView(model: container.makeProgressViewModel())
    }
    .environment(container)
}
