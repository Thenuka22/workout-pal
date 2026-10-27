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
    private(set) var isLoading = true
    private(set) var isStarting = false
    private(set) var isFinishing = false
    private(set) var errorMessage: String?
    private(set) var needsSaveRetry = false
    private var banked = PedometerReading.zero
    private var segment = PedometerReading.zero

    private let motion: any MotionTracking
    private let permissions: any PermissionsProviding
    private let activities: any ActivitySessionRepository
    private let exporter: HealthExporter
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    @ObservationIgnored private var readingsTask: Task<Void, Never>?
    @ObservationIgnored private var motionTask: Task<Void, Never>?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var motionCounts: [DetectedMotion: Int] = [:]

    init(
        motion: any MotionTracking,
        permissions: any PermissionsProviding,
        activities: any ActivitySessionRepository,
        exporter: HealthExporter,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.motion = motion
        self.permissions = permissions
        self.activities = activities
        self.exporter = exporter
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

    var errorTitle: String {
        needsSaveRetry ? "Couldn't save this session" : "Tracking stopped"
    }

    func elapsedSeconds(at date: Date) -> Double {
        activity?.activeSeconds(at: date) ?? 0
    }

    func load() async {
        defer { isLoading = false }
        if let activity {
            if !activity.isPaused, let current = activity.activeIntervals(at: now()).last {
                startUpdates(from: current.start)
            }
            return
        }
        guard finishedActivity == nil else {
            return
        }
        do {
            guard let active = try await activities.activeActivity(ownerID: settings.ownerID) else {
                return
            }
            restore(active)
        } catch {
            errorMessage = error.localizedDescription
        }
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
            let activity = ActivitySession.start(kind: self.kind, ownerID: self.settings.ownerID, now: self.now())
            self.begin(activity)
            self.persist(activity)
        }
    }

    func pause() {
        guard var activity, !activity.isPaused else {
            return
        }
        stopUpdates()
        activity.pauses = SessionTiming.pausing(activity.pauses, at: now())
        activity.steps = steps
        self.activity = activity
        banked = banked.adding(segment)
        segment = .zero
        persist(activity)
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
        persist(activity)
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
        activity.detectedMotion = MotionSummary.dominantMotion(motionCounts) ?? activity.detectedMotion
        let estimate = banked.adding(segment)
        let ending = activity
        isFinishing = true
        Task {
            let measured = await self.measuredTotal(for: ending, until: end) ?? estimate
            var finished = ending
            finished.steps = max(measured.steps, 0)
            finished.distanceMeters = self.capabilities.canMeasureDistance ? measured.distanceMeters ?? 0 : nil
            await self.previousSave()
            do {
                try await self.activities.save(finished)
            } catch {
                self.needsSaveRetry = true
                self.errorMessage = error.localizedDescription
                self.complete(finished)
                return
            }
            self.complete(finished)
            await self.exportIfEnabled(finished)
        }
    }

    func retrySave() {
        guard needsSaveRetry, let finished = finishedActivity, !isFinishing else {
            return
        }
        isFinishing = true
        errorMessage = nil
        Task {
            do {
                try await self.activities.save(finished)
                self.needsSaveRetry = false
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isFinishing = false
            if !self.needsSaveRetry {
                await self.exportIfEnabled(finished)
            }
        }
    }

    func discard() {
        if needsSaveRetry {
            discardUnsaved()
            return
        }
        guard let activity else {
            return
        }
        stopUpdates()
        self.activity = nil
        banked = .zero
        segment = .zero
        let id = activity.id
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.activities.deleteActivity(id: id)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func discardUnsaved() {
        guard let finished = finishedActivity, !isFinishing else {
            return
        }
        needsSaveRetry = false
        finishedActivity = nil
        errorMessage = nil
        let id = finished.id
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.activities.deleteActivity(id: id)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func startAnother() {
        finishedActivity = nil
        needsSaveRetry = false
    }

    func suspendUpdates() {
        stopUpdates()
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

    private func restore(_ active: ActivitySession) {
        kind = active.kind
        activity = active
        detectedMotion = active.detectedMotion
        banked = PedometerReading(steps: active.steps, distanceMeters: nil)
        segment = .zero
        motionCounts = [:]
        let date = now()
        if !active.isPaused, let current = active.activeIntervals(at: date).last {
            banked = .zero
            startUpdates(from: current.start)
        }
        Task {
            await self.reconcileClosedSegments()
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

    private func exportIfEnabled(_ finished: ActivitySession) async {
        guard settings.preferences.exportsToHealth else {
            return
        }
        let status = await exporter.export(.activity(finished))
        finishedActivity?.healthExport = status
    }

    private func complete(_ finished: ActivitySession) {
        finishedActivity = finished
        activity = nil
        banked = .zero
        segment = .zero
        isFinishing = false
    }

    private func persist(_ activity: ActivitySession) {
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.activities.save(activity)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func previousSave() async {
        await saveTask?.value
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
        let detections = motion.activities()
        motionTask = Task {
            for await detected in detections {
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
        guard let activity else {
            return
        }
        let date = now()
        var closed = activity.activeIntervals(at: date)
        if !activity.isPaused, let last = closed.last, last.end >= date {
            closed.removeLast()
        }
        var total = PedometerReading.zero
        for interval in closed {
            guard let reading = try? await motion.reading(from: interval.start, to: interval.end) else {
                return
            }
            total = total.adding(reading)
        }
        guard self.activity?.id == activity.id, total.steps >= banked.steps else {
            return
        }
        banked = total
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
