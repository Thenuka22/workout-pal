import Foundation

struct HealthWorkoutSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let startedAt: Date
    let durationSeconds: Double
    let sourceName: String
}

struct HealthDaySummary: Hashable, Sendable {
    static let dailyStepGoal = 8_000

    var steps: Int?
    var distanceMeters: Double?
    var otherWorkouts: [HealthWorkoutSummary]

    var stepProgress: Double {
        guard let steps else {
            return 0
        }
        return min(Double(steps) / Double(Self.dailyStepGoal), 1)
    }
}

enum HealthCardState: Equatable {
    case unavailable
    case notConnected
    case loading
    case loaded(HealthDaySummary, updatedAt: Date)
    case failed(String)
}

enum HealthWorkoutKind: Sendable {
    case strength
    case walk
    case run
}

struct HealthWorkoutExport: Hashable, Sendable {
    let id: UUID
    let kind: HealthWorkoutKind
    let start: Date
    let end: Date
    let pauses: [DateInterval]

    init(id: UUID, kind: HealthWorkoutKind, start: Date, end: Date, pauses: [DateInterval]) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.pauses = pauses
    }

    init?(session: WorkoutSession) {
        guard session.status == .completed, let end = session.endedAt, end > session.startedAt else {
            return nil
        }
        self.init(
            id: session.id,
            kind: .strength,
            start: session.startedAt,
            end: end,
            pauses: Self.closedPauses(session.pauses, start: session.startedAt, end: end)
        )
    }

    init?(activity: ActivitySession) {
        guard activity.status == .completed, let end = activity.endedAt, end > activity.startedAt else {
            return nil
        }
        self.init(
            id: activity.id,
            kind: activity.kind == .run ? .run : .walk,
            start: activity.startedAt,
            end: end,
            pauses: Self.closedPauses(activity.pauses, start: activity.startedAt, end: end)
        )
    }

    var activeSeconds: Double {
        end.timeIntervalSince(start) - pauses.reduce(0) { $0 + $1.duration }
    }

    static func closedPauses(_ pauses: [PauseInterval], start: Date, end: Date) -> [DateInterval] {
        pauses.compactMap { pause in
            guard let pauseEnd = pause.end else {
                return nil
            }
            let from = max(pause.start, start)
            let to = min(pauseEnd, end)
            return to > from ? DateInterval(start: from, end: to) : nil
        }
    }
}
