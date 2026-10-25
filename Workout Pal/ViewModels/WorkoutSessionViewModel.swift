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
    var finishSummary: WorkoutFinishSummary?
    var selectedExerciseID: UUID?

    private let repository: any WorkoutSessionRepository
    private let exporter: HealthExporter
    private let notifications: any NotificationScheduling
    private let feedback: any WorkoutFeedback
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var restTask: Task<Void, Never>?

    init(
        session: WorkoutSession,
        repository: any WorkoutSessionRepository,
        exporter: HealthExporter,
        notifications: any NotificationScheduling,
        feedback: any WorkoutFeedback,
        settings: AppSettings,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.session = session
        self.repository = repository
        self.exporter = exporter
        self.notifications = notifications
        self.feedback = feedback
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

    var progressText: String {
        "\(session.completedSetCount) of \(session.totalSetCount) sets"
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

    func start() {
        persist()
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

    func finish() {
        skipRest()
        let end = now()
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

    func closeSummary() {
        finishSummary = nil
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
