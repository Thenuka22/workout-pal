import Foundation

enum RoutinePlanner {
    static func nextRoutine(from routines: [Routine], sessions: [WorkoutSession]) -> Routine? {
        var lastCompleted: [UUID: Date] = [:]
        for session in sessions where session.status == .completed {
            guard let routineID = session.routineID else {
                continue
            }
            lastCompleted[routineID] = max(lastCompleted[routineID] ?? .distantPast, session.startedAt)
        }
        return routines.min { lhs, rhs in
            let lhsDate = lastCompleted[lhs.id] ?? .distantPast
            let rhsDate = lastCompleted[rhs.id] ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
}
