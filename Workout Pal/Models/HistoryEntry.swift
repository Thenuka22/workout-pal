import Foundation

enum HistoryEntry: Identifiable, Hashable, Sendable {
    case workout(WorkoutSession)
    case activity(ActivitySession)

    var id: UUID {
        switch self {
        case .workout(let session): session.id
        case .activity(let activity): activity.id
        }
    }

    var startedAt: Date {
        switch self {
        case .workout(let session): session.startedAt
        case .activity(let activity): activity.startedAt
        }
    }

    var title: String {
        switch self {
        case .workout(let session): session.routineName
        case .activity(let activity): activity.kind.title
        }
    }

    var activeSeconds: Double {
        switch self {
        case .workout(let session): session.activeSeconds
        case .activity(let activity): activity.activeSeconds
        }
    }

    static func merge(workouts: [WorkoutSession], activities: [ActivitySession]) -> [HistoryEntry] {
        (workouts.map { HistoryEntry.workout($0) } + activities.map { HistoryEntry.activity($0) })
            .sorted { $0.startedAt > $1.startedAt }
    }
}
