import SwiftUI

struct ProgressHomeView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case history = "History"
        case charts = "Charts"

        var id: String { rawValue }
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: ProgressHomeViewModel
    @State private var tab: Tab = .history
    @State private var selectedSession: WorkoutSession?

    init(model: ProgressHomeViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            if let message = model.errorMessage {
                ErrorStateView(title: "Could not load your history", message: message) {
                    model.retry()
                }
                .screenBackground()
            } else if model.sessions.isEmpty && !model.isLoading {
                ContentUnavailableView(
                    "No completed workouts",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Finish a workout to see your history and charts.")
                )
                .screenBackground()
            } else if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedSession: $selectedSession)
                        .frame(width: 380)
                    Divider()
                    if let selectedSession {
                        WorkoutDetailView(session: selectedSession, units: model.units)
                    } else {
                        ProgressChartsView(model: model)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    Picker("Section", selection: $tab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColors.surface)
                    switch tab {
                    case .history:
                        WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedSession: nil)
                    case .charts:
                        ProgressChartsView(model: model)
                    }
                }
            }
        }
        .navigationTitle("Progress")
        .toolbar {
            if horizontalSizeClass == .regular && selectedSession != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show charts") {
                        selectedSession = nil
                    }
                }
            }
        }
        .navigationDestination(for: WorkoutSession.self) { session in
            WorkoutDetailView(session: session, units: model.units)
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
}

#Preview {
    NavigationStack {
        ProgressHomeView(model: AppContainer(inMemory: true).makeProgressViewModel())
    }
}
