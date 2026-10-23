import Foundation

enum ActivityKind: String, CaseIterable, Identifiable, Sendable {
    case walk
    case run

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walk: "Walk"
        case .run: "Run"
        }
    }

    var symbolName: String {
        switch self {
        case .walk: "figure.walk"
        case .run: "figure.run"
        }
    }
}

enum DetectedMotion: String, CaseIterable, Sendable {
    case stationary
    case walking
    case running
    case cycling
    case automotive
    case unknown

    var title: String {
        switch self {
        case .stationary: "Standing still"
        case .walking: "Walking"
        case .running: "Running"
        case .cycling: "Cycling"
        case .automotive: "In a vehicle"
        case .unknown: "Not sure yet"
        }
    }
}

struct ActivitySession: Identifiable, Hashable, Sendable {
    let id: UUID
    var ownerID: String
    var kind: ActivityKind
    var status: SessionStatus
    var startedAt: Date
    var endedAt: Date?
    var pauses: [PauseInterval]
    var steps: Int
    var distanceMeters: Double?
    var detectedMotion: DetectedMotion?
    var healthExport: HealthExportStatus

    var isPaused: Bool {
        SessionTiming.isPaused(pauses)
    }

    var activeSeconds: Double {
        activeSeconds(at: .now)
    }

    func activeSeconds(at now: Date) -> Double {
        SessionTiming.activeSeconds(startedAt: startedAt, endedAt: endedAt, pauses: pauses, now: now)
    }

    func activeIntervals(at now: Date) -> [DateInterval] {
        SessionTiming.activeIntervals(startedAt: startedAt, endedAt: endedAt, pauses: pauses, now: now)
    }

    static func start(kind: ActivityKind, ownerID: String, now: Date = .now) -> ActivitySession {
        ActivitySession(
            id: UUID(),
            ownerID: ownerID,
            kind: kind,
            status: .active,
            startedAt: now,
            endedAt: nil,
            pauses: [],
            steps: 0,
            distanceMeters: nil,
            detectedMotion: nil,
            healthExport: .notExported
        )
    }
}
