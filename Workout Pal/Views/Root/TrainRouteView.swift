import SwiftUI

struct TrainRouteView: View {
    @Environment(AppContainer.self) private var container
    let route: TrainRoute

    var body: some View {
        switch route {
        case .routine(let id):
            RoutineDetailView(model: container.makeRoutineDetailViewModel(routineID: id), embedded: false)
        case .repCounter:
            RepCounterView(model: container.makeRepCounterViewModel())
        case .activityTracker:
            ActivityTrackerView(model: container.makeActivityTrackerViewModel())
        }
    }
}
