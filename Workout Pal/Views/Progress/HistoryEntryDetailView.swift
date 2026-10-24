import SwiftUI

struct HistoryEntryDetailView: View {
    let entry: HistoryEntry
    let units: UnitPreference

    var body: some View {
        switch entry {
        case .workout(let session):
            WorkoutDetailView(session: session, units: units)
        case .activity(let activity):
            ActivityDetailView(activity: activity, units: units)
        }
    }
}
