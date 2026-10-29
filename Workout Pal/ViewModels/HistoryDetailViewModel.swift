import Foundation
import Observation

@MainActor
@Observable
final class HistoryDetailViewModel {
    private(set) var entry: HistoryEntry
    private(set) var isExporting = false
    private(set) var isDeleted = false
    private(set) var errorMessage: String?

    private let sessions: any WorkoutSessionRepository
    private let activities: any ActivitySessionRepository
    private let exporter: HealthExporter
    private let settings: AppSettings

    init(
        entry: HistoryEntry,
        sessions: any WorkoutSessionRepository,
        activities: any ActivitySessionRepository,
        exporter: HealthExporter,
        settings: AppSettings
    ) {
        self.entry = entry
        self.sessions = sessions
        self.activities = activities
        self.exporter = exporter
        self.settings = settings
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var shareText: String {
        ShareSummary.text(for: entry, units: units)
    }

    var exportStatus: HealthExportStatus {
        switch entry {
        case .workout(let session): session.healthExport
        case .activity(let activity): activity.healthExport
        }
    }

    var canExport: Bool {
        exporter.isAvailable && exportStatus != .exported
    }

    var exportTitle: String {
        exportStatus == .failed ? "Try again" : "Save to Apple Health"
    }

    var deleteMessage: String {
        if exportStatus == .exported {
            return "This removes it from Workout Pal. The copy in Apple Health stays until you delete it in the Health app."
        }
        return "This removes it from your Workout Pal history."
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func exportToHealth() {
        guard canExport, !isExporting else {
            return
        }
        isExporting = true
        let entry = entry
        Task {
            let status = await self.exporter.export(entry)
            self.apply(status)
            if status == .failed {
                self.errorMessage = "Workout Pal couldn't save this to Apple Health. Check that saving workouts is allowed in the Health app, then try again."
            }
            self.isExporting = false
        }
    }

    func delete() {
        let entry = entry
        Task {
            do {
                switch entry {
                case .workout(let session):
                    try await self.sessions.deleteSession(id: session.id)
                case .activity(let activity):
                    try await self.activities.deleteActivity(id: activity.id)
                }
                self.isDeleted = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func apply(_ status: HealthExportStatus) {
        switch entry {
        case .workout(var session):
            session.healthExport = status
            entry = .workout(session)
        case .activity(var activity):
            activity.healthExport = status
            entry = .activity(activity)
        }
    }
}
