import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct WorkoutSessionViewModelTests {
    private let clock = TestClock(SampleData.now)
    private let repository = InMemoryWorkoutSessionRepository()

    private func makeModel(rest: Int = 60) -> WorkoutSessionViewModel {
        var exercise = SampleData.exercise(sets: [
            SampleData.set(isCompleted: false),
            SampleData.set(reps: 8, load: .kilograms(30), isCompleted: false),
        ])
        exercise.restSeconds = rest
        let session = SampleData.session(startedAt: clock.now, status: .active, exercises: [exercise])
        let clock = clock
        return WorkoutSessionViewModel(
            session: session,
            repository: repository,
            settings: AppSettings(store: InMemoryPreferencesStore()),
            now: { clock.now }
        )
    }

    private func firstSet(_ model: WorkoutSessionViewModel) -> (exercise: UUID, set: UUID) {
        let exercise = model.session.exercises[0]
        return (exercise.id, exercise.sets[0].id)
    }

    @Test func completingASetStampsItAndStartsRest() {
        let model = makeModel(rest: 90)
        clock.advance(by: 45)
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        let set = model.session.exercises[0].sets[0]
        #expect(set.isCompleted)
        #expect(set.completedAt == clock.now)
        #expect(model.restEndsAt == clock.now.addingTimeInterval(90))
        #expect(model.progressText == "1 of 2 sets")
    }

    @Test func undoingASetClearsItsTime() {
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        #expect(!model.session.exercises[0].sets[0].isCompleted)
        #expect(model.session.exercises[0].sets[0].completedAt == nil)
    }

    @Test func pausedTimeIsNotCounted() async {
        let model = makeModel()
        clock.advance(by: 60)
        model.pause()
        #expect(model.isPaused)
        clock.advance(by: 120)
        #expect(model.elapsedSeconds(at: clock.now) == 60)
        model.resume()
        clock.advance(by: 30)
        model.finish()
        #expect(await eventually { model.isFinished })
        let saved = await repository.stored(id: model.session.id)
        #expect(saved?.status == .completed)
        #expect(saved?.activeSeconds == 90)
        #expect(saved?.endedAt == clock.now)
    }

    @Test func finishingWhilePausedClosesThePause() async {
        let model = makeModel()
        clock.advance(by: 100)
        model.pause()
        clock.advance(by: 50)
        model.finish()
        #expect(await eventually { model.isFinished })
        #expect(!model.session.isPaused)
        #expect(model.session.activeSeconds == 100)
    }

    @Test func pausingSkipsTheRestTimer() {
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.pause()
        #expect(model.restEndsAt == nil)
    }

    @Test func completingASetWhilePausedResumes() {
        let model = makeModel()
        model.pause()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        #expect(!model.isPaused)
    }

    @Test func newSetCopiesThePreviousOne() {
        let model = makeModel()
        let exerciseID = model.session.exercises[0].id
        model.addSet(to: exerciseID)
        let sets = model.session.exercises[0].sets
        #expect(sets.count == 3)
        #expect(sets[2].reps == 8)
        #expect(sets[2].load == .kilograms(30))
        #expect(!sets[2].isCompleted)
    }

    @Test func failedSaveIsReported() async {
        await repository.failSaves(with: CocoaError(.fileWriteUnknown))
        let model = makeModel()
        model.finish()
        #expect(await eventually { model.errorMessage != nil })
        #expect(!model.isFinished)
    }
}
