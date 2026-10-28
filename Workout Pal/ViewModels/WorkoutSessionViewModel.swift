import Foundation
import Observation

@MainActor
@Observable
final class WorkoutSessionViewModel {
    private(set) var session: WorkoutSession
    private(set) var restStartedAt: Date?
    private(set) var restEndsAt: Date?
    private(set) var errorMessage: String?
    private(set) var isFinished = false
    private(set) var isFinishing = false
    private(set) var isDiscarded = false
    private(set) var finishSummary: WorkoutFinishSummary?
    var selectedExerciseID: UUID?
    var isAskingAboutStaleSession = false

    private let repository: any WorkoutSessionRepository
    private let exporter: HealthExporter
    private let notifications: any NotificationScheduling
    private let feedback: any WorkoutFeedback
    private let permissions: any PermissionsProviding
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private var hasCheckedStaleness = false

    init(
        session: WorkoutSession,
        repository: any WorkoutSessionRepository,
        exporter: HealthExporter,
        notifications: any NotificationScheduling,
        feedback: any WorkoutFeedback,
        permissions: any PermissionsProviding,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.session = session
        self.repository = repository
        self.exporter = exporter
        self.notifications = notifications
        self.feedback = feedback
        self.permissions = permissions
        self.settings = settings
        self.now = now
        selectedExerciseID = session.exercises.first?.id
    }

    var units: UnitPreference {
        settings.preferences.units
    }

    var isPaused: Bool {
        session.isPaused
    }

    var selectedExercise: SessionExercise? {
        session.exercises.first { $0.id == selectedExerciseID } ?? session.exercises.first
    }

    var hasCompletedSets: Bool {
        session.completedSetCount > 0
    }

    var progressText: String {
        "\(session.completedSetCount) of \(Formatting.count(session.totalSetCount, "set"))"
    }

    var nextExerciseName: String? {
        let exercises = session.exercises
        var latestIndex = -1
        var latestDate = Date.distantPast
        for (index, exercise) in exercises.enumerated() {
            for set in exercise.sets {
                if let date = set.completedAt, date > latestDate {
                    latestDate = date
                    latestIndex = index
                }
            }
        }
        let start = latestIndex + 1
        guard start < exercises.count else {
            return nil
        }
        return exercises[start...].first { exercise in
            exercise.sets.contains { !$0.isCompleted }
        }?.exerciseName
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
        session.activeSeconds(at: date)
    }

    var lastSetTimeText: String? {
        session.lastSetAt.map { $0.formatted(date: .omitted, time: .shortened) }
    }

    var staleMessage: String {
        let opened = "This workout has been open since \(Formatting.dateTime(session.startedAt))."
        if lastSetTimeText != nil {
            return "\(opened) Finish it at your last set so the time since then isn't counted."
        }
        return "\(opened) No sets are done yet."
    }

    func start() {
        if !hasCheckedStaleness {
            hasCheckedStaleness = true
            isAskingAboutStaleSession = session.isStale(at: now())
        }
        persist()
        resumeRestIfNeeded()
        guard settings.preferences.restAlertsEnabled else {
            return
        }
        Task {
            if await self.permissions.status(of: .notifications) == .notDetermined {
                _ = await self.permissions.request(.notifications)
            }
        }
    }

    func pause() {
        guard !isPaused else {
            return
        }
        skipRest()
        session.pauses = SessionTiming.pausing(session.pauses, at: now())
        persist()
    }

    func resume() {
        guard isPaused else {
            return
        }
        session.pauses = SessionTiming.resuming(session.pauses, at: now())
        persist()
    }

    func addSet(to exerciseID: UUID) {
        guard let index = exerciseIndex(exerciseID) else {
            return
        }
        let last = session.exercises[index].sets.last
        session.exercises[index].sets.append(WorkoutSet(
            id: UUID(),
            reps: last?.reps ?? 10,
            load: last?.load ?? .bodyweight,
            isCompleted: false,
            completedAt: nil,
            source: .manual
        ))
        persist()
    }

    func removeSet(exerciseID: UUID, setID: UUID) {
        guard let index = exerciseIndex(exerciseID) else {
            return
        }
        session.exercises[index].sets.removeAll { $0.id == setID }
        persist()
    }

    func updateReps(exerciseID: UUID, setID: UUID, reps: Int) {
        update(exerciseID: exerciseID, setID: setID) { $0.reps = max(0, reps) }
    }

    func updateLoad(exerciseID: UUID, setID: UUID, load: Load) {
        update(exerciseID: exerciseID, setID: setID) { $0.load = load }
    }

    func setBodyweight(exerciseID: UUID, setID: UUID, isOn: Bool) {
        guard let index = exerciseIndex(exerciseID) else {
            return
        }
        let load: Load = isOn ? .bodyweight : .kilograms(lastKilograms(in: session.exercises[index]) ?? 20)
        updateLoad(exerciseID: exerciseID, setID: setID, load: load)
    }

    func toggleCompletion(exerciseID: UUID, setID: UUID) {
        guard let index = exerciseIndex(exerciseID),
              let setIndex = session.exercises[index].sets.firstIndex(where: { $0.id == setID })
        else {
            return
        }
        let completed = !session.exercises[index].sets[setIndex].isCompleted
        let date = now()
        if completed && isPaused {
            session.pauses = SessionTiming.resuming(session.pauses, at: date)
        }
        session.exercises[index].sets[setIndex].isCompleted = completed
        session.exercises[index].sets[setIndex].completedAt = completed ? date : nil
        if completed {
            feedback.setCompleted()
            startRest(seconds: session.exercises[index].restSeconds)
        }
        persist()
    }

    func cameraExercise(for exercise: SessionExercise) -> CameraExercise? {
        CameraExercise.matching(exerciseName: exercise.exerciseName)
    }

    func addCameraSet(exerciseID: UUID, reps: Int) {
        guard reps > 0, let index = exerciseIndex(exerciseID) else {
            return
        }
        let date = now()
        if isPaused {
            session.pauses = SessionTiming.resuming(session.pauses, at: date)
        }
        let sets = session.exercises[index].sets
        if let setIndex = sets.firstIndex(where: { !$0.isCompleted }) {
            session.exercises[index].sets[setIndex].reps = reps
            session.exercises[index].sets[setIndex].isCompleted = true
            session.exercises[index].sets[setIndex].completedAt = date
            session.exercises[index].sets[setIndex].source = .camera
        } else {
            session.exercises[index].sets.append(WorkoutSet(
                id: UUID(),
                reps: reps,
                load: sets.last?.load ?? .bodyweight,
                isCompleted: true,
                completedAt: date,
                source: .camera
            ))
        }
        feedback.setCompleted()
        startRest(seconds: session.exercises[index].restSeconds)
        persist()
    }

    func skipRest() {
        let hadRest = restEndsAt != nil
        restTask?.cancel()
        restTask = nil
        restStartedAt = nil
        restEndsAt = nil
        if hadRest {
            Task {
                await self.notifications.cancelRestAlert()
            }
        }
    }

    func disappear() {
        restTask?.cancel()
        restTask = nil
    }

    func finish() {
        finish(at: now())
    }

    func finishAtLastSet() {
        guard let lastSet = session.lastSetAt else {
            return
        }
        finish(at: lastSet)
    }

    private func finish(at end: Date) {
        guard !isFinishing else {
            return
        }
        isFinishing = true
        skipRest()
        session.pauses = SessionTiming.resuming(session.pauses, at: end)
        session.status = .completed
        session.endedAt = end
        session.activeSeconds = session.activeSeconds(at: end)
        let snapshot = session
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.repository.save(snapshot)
                self.isFinished = true
            } catch {
                self.errorMessage = error.localizedDescription
                self.isFinishing = false
                return
            }
            let history = (try? await self.repository.completedSessions(ownerID: snapshot.ownerID)) ?? []
            self.finishSummary = WorkoutFinishSummary(
                session: snapshot,
                records: RecordBook.newRecords(in: snapshot, previous: history)
            )
            if self.settings.preferences.exportsToHealth {
                _ = await self.exporter.export(.workout(snapshot))
            }
        }
    }

    func discard() {
        guard !isFinishing else {
            return
        }
        isFinishing = true
        skipRest()
        let id = session.id
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.repository.deleteSession(id: id)
                self.isDiscarded = true
            } catch {
                self.errorMessage = error.localizedDescription
                self.isFinishing = false
            }
        }
    }

    private func startRest(seconds: Int) {
        restTask?.cancel()
        guard seconds > 0 else {
            restStartedAt = nil
            restEndsAt = nil
            return
        }
        let start = now()
        let end = start.addingTimeInterval(TimeInterval(seconds))
        restStartedAt = start
        restEndsAt = end
        if settings.preferences.restAlertsEnabled {
            let next = nextExerciseName
            Task {
                await self.notifications.scheduleRestAlert(at: end, nextExercise: next)
            }
        }
        armRest(for: TimeInterval(seconds))
    }

    private func resumeRestIfNeeded() {
        guard restTask == nil, let end = restEndsAt else {
            return
        }
        let remaining = end.timeIntervalSince(now())
        if remaining > 0 {
            armRest(for: remaining)
        } else {
            restStartedAt = nil
            restEndsAt = nil
        }
    }

    private func armRest(for seconds: TimeInterval) {
        restTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled {
                self.restStartedAt = nil
                self.restEndsAt = nil
                self.feedback.restFinished()
            }
        }
    }

    private func update(exerciseID: UUID, setID: UUID, _ change: (inout WorkoutSet) -> Void) {
        guard let index = exerciseIndex(exerciseID),
              let setIndex = session.exercises[index].sets.firstIndex(where: { $0.id == setID })
        else {
            return
        }
        change(&session.exercises[index].sets[setIndex])
        persist()
    }

    private func lastKilograms(in exercise: SessionExercise) -> Double? {
        exercise.sets.reversed().compactMap(\.load.kilograms).first { $0 > 0 }
    }

    private func exerciseIndex(_ exerciseID: UUID) -> Int? {
        session.exercises.firstIndex { $0.id == exerciseID }
    }

    private func persist() {
        let snapshot = session
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.repository.save(snapshot)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
