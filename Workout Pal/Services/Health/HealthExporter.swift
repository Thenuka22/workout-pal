struct HealthExporter: Sendable {
    let health: any HealthService
    let sessions: any WorkoutSessionRepository
    let activities: any ActivitySessionRepository

    var isAvailable: Bool {
        health.isAvailable
    }

    func export(_ entry: HistoryEntry) async -> HealthExportStatus {
        switch entry {
        case .workout(let session):
            guard let workout = HealthWorkoutExport(session: session) else {
                return session.healthExport
            }
            let status = await save(workout)
            try? await sessions.updateHealthExport(id: session.id, status: status)
            return status
        case .activity(let activity):
            guard let workout = HealthWorkoutExport(activity: activity) else {
                return activity.healthExport
            }
            let status = await save(workout)
            try? await activities.updateHealthExport(id: activity.id, status: status)
            return status
        }
    }

    private func save(_ workout: HealthWorkoutExport) async -> HealthExportStatus {
        guard health.isAvailable else {
            return .failed
        }
        do {
            try await health.saveWorkout(workout)
            return .exported
        } catch {
            return .failed
        }
    }
}
