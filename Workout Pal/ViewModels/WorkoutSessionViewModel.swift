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
    var selectedExerciseID: UUID?

    private let repository: any WorkoutSessionRepository
    private let settings: AppSettings
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var restTask: Task<Void, Never>?

    init(session: WorkoutSession, repository: any WorkoutSessionRepository, settings: AppSettings) {
        self.session = session
        self.repository = repository
        self.settings = settings
        selectedExerciseID = session.exercises.first?.id
    }

    var units: UnitPreference {
        settings.preferences.units
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

    func start() {
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
        session.exercises[index].sets[setIndex].isCompleted = completed
        session.exercises[index].sets[setIndex].completedAt = completed ? .now : nil
        if completed {
            startRest(seconds: session.exercises[index].restSeconds)
        }
        persist()
    }

    func skipRest() {
        restTask?.cancel()
        restTask = nil
        restStartedAt = nil
        restEndsAt = nil
    }

    func finish() {
        skipRest()
        let now = Date.now
        session.status = .completed
        session.endedAt = now
        session.activeSeconds = max(0, now.timeIntervalSince(session.startedAt))
        let snapshot = session
        let previous = saveTask
        saveTask = Task {
            await previous?.value
            do {
                try await self.repository.save(snapshot)
                self.isFinished = true
            } catch {
                self.errorMessage = error.localizedDescription
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
        let start = Date.now
        restStartedAt = start
        restEndsAt = start.addingTimeInterval(TimeInterval(seconds))
        restTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled {
                self.restStartedAt = nil
                self.restEndsAt = nil
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
