import Foundation
import Observation

@MainActor
@Observable
final class ActivityTrackerViewModel {
    let kinds = ActivityKind.allCases
    var kind: ActivityKind = .walk

    private(set) var activity: ActivitySession?
    private(set) var finishedActivity: ActivitySession?
    private(set) var capabilities: MotionCapabilities
    private(set) var motionAccess: PermissionStatus = .notDetermined
    private(set) var detectedMotion: DetectedMotion?
    private(set) var isStarting = false
    private(set) var isFinishing = false
    private(set) var errorMessage: String?
    private var banked = PedometerReading.zero
    private var segment = PedometerReading.zero

    private let motion: any MotionTracking
    private let permissions: any PermissionsProviding
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    @ObservationIgnored private var readingsTask: Task<Void, Never>?
    @ObservationIgnored private var motionTask: Task<Void, Never>?
    @ObservationIgnored private var motionCounts: [DetectedMotion: Int] = [:]

    init(
        motion: any MotionTracking,
        permissions: any PermissionsProviding,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.motion = motion
        self.permissions = permissions
        self.settings = settings
        self.now = now
        capabilities = motion.capabilities()
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var isAvailable: Bool {
        capabilities.canCountSteps
    }

    var isPaused: Bool {
        activity?.isPaused ?? false
    }

    var statusTitle: String {
        guard let activity else {
            return "Ready"
        }
        return activity.isPaused ? "Paused" : "Tracking"
    }

    var isAccessBlocked: Bool {
        motionAccess == .denied || motionAccess == .restricted
    }

    var steps: Int {
        banked.adding(segment).steps
    }

    var distanceText: String {
        guard capabilities.canMeasureDistance else {
            return "Unavailable"
        }
        let meters = banked.adding(segment).distanceMeters ?? 0
        return Formatting.distance(meters: meters, units: settings.preferences.units)
    }

    var detectedText: String {
        guard capabilities.canDetectActivity else {
            return "Unavailable"
        }
        return detectedMotion?.title ?? "Waiting for movement"
    }

    var startTitle: String {
        "Start \(kind.title.lowercased())"
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func elapsedSeconds(at date: Date) -> Double {
        activity?.activeSeconds(at: date) ?? 0
    }

    func start() {
        guard isAvailable, activity == nil, !isStarting else {
            return
        }
        isStarting = true
        Task {
            let access = await self.permissions.request(.motion)
            self.motionAccess = access
            self.isStarting = false
            guard access == .granted else {
                return
            }
            let activity = ActivitySession.start(kind: self.kind, ownerID: LocalProfile.ownerID, now: self.now())
            self.begin(activity)
        }
    }

    func pause() {
        guard var activity, !activity.isPaused else {
            return
        }
        stopUpdates()
        activity.pauses = SessionTiming.pausing(activity.pauses, at: now())
        self.activity = activity
        banked = banked.adding(segment)
        segment = .zero
        Task {
            await self.reconcileClosedSegments()
        }
    }

    func resume() {
        guard var activity, activity.isPaused else {
            return
        }
        let date = now()
        activity.pauses = SessionTiming.resuming(activity.pauses, at: date)
        self.activity = activity
        segment = .zero
        startUpdates(from: date)
    }

    func finish() {
        guard var activity, !isFinishing else {
            return
        }
        let end = now()
        stopUpdates()
        activity.pauses = SessionTiming.resuming(activity.pauses, at: end)
        activity.endedAt = end
        activity.status = .completed
        activity.detectedMotion = MotionSummary.dominantMotion(motionCounts)
        let estimate = banked.adding(segment)
        let ending = activity
        isFinishing = true
        Task {
            let measured = await self.measuredTotal(for: ending, until: end) ?? estimate
            var finished = ending
            finished.steps = measured.steps
            finished.distanceMeters = self.capabilities.canMeasureDistance ? measured.distanceMeters ?? 0 : nil
            self.complete(finished)
        }
    }

    func discard() {
        stopUpdates()
        activity = nil
        banked = .zero
        segment = .zero
    }

    func startAnother() {
        finishedActivity = nil
    }

    func scenePhaseChanged(isActive: Bool) {
        guard isActive, let activity, !activity.isPaused,
              let current = activity.activeIntervals(at: now()).last
        else {
            return
        }
        let start = current.start
        let end = current.end
        Task {
            if let reading = try? await self.motion.reading(from: start, to: end), reading.steps > self.segment.steps {
                self.segment = reading
            }
        }
    }

    private func begin(_ activity: ActivitySession) {
        self.activity = activity
        finishedActivity = nil
        banked = .zero
        segment = .zero
        motionCounts = [:]
        detectedMotion = nil
        startUpdates(from: activity.startedAt)
    }

    private func complete(_ finished: ActivitySession) {
        finishedActivity = finished
        activity = nil
        banked = .zero
        segment = .zero
        isFinishing = false
    }

    private func startUpdates(from date: Date) {
        stopUpdates()
        let readings = motion.readings(from: date)
        readingsTask = Task {
            do {
                for try await reading in readings {
                    self.segment = reading
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        guard capabilities.canDetectActivity else {
            return
        }
        let activities = motion.activities()
        motionTask = Task {
            for await detected in activities {
                self.record(detected)
            }
        }
    }

    private func stopUpdates() {
        readingsTask?.cancel()
        motionTask?.cancel()
        readingsTask = nil
        motionTask = nil
    }

    private func record(_ detected: DetectedMotion) {
        detectedMotion = detected
        motionCounts[detected, default: 0] += 1
    }

    private func reconcileClosedSegments() async {
        guard let activity, activity.isPaused else {
            return
        }
        if let measured = await measuredTotal(for: activity, until: now()), measured.steps >= banked.steps {
            banked = measured
        }
    }

    private func measuredTotal(for activity: ActivitySession, until end: Date) async -> PedometerReading? {
        var total = PedometerReading.zero
        for interval in activity.activeIntervals(at: end) {
            guard let reading = try? await motion.reading(from: interval.start, to: interval.end) else {
                return nil
            }
            total = total.adding(reading)
        }
        return total
    }
}
