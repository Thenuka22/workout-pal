import SwiftUI

struct ProgressHomeView: View {
    private enum Panel: String, CaseIterable, Identifiable {
        case charts = "Charts"
        case history = "History"

        var id: String { rawValue }
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var model: ProgressHomeViewModel
    @State private var panel: Panel = .charts
    @State private var selectedSession: WorkoutSession?

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

    @ViewBuilder
    private var content: some View {
        if let message = model.errorMessage {
            ErrorStateView(title: "Could not load your history", message: message) {
                model.retry()
            }
        } else if model.sessions.isEmpty && !model.isLoading {
            ContentUnavailableView(
                "No completed workouts",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Finish a workout to see your history and charts.")
            )
        } else if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedSession: $selectedSession)
                    .frame(width: 380)
                Divider()
                if let selectedSession {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("Show charts") {
                                self.selectedSession = nil
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.top, AppSpacing.small)
                        WorkoutDetailView(session: selectedSession, units: model.units)
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
                WorkoutHistoryView(groups: model.historyGroups, units: model.units, selectedSession: nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressHomeView(model: AppContainer(inMemory: true).makeProgressViewModel())
    }
}
