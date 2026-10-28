import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct WorkoutSessionViewModelTests {
    private let clock = TestClock(SampleData.now)
    private let repository = InMemoryWorkoutSessionRepository()
    private let health = FakeHealthService()
    private let store = InMemoryPreferencesStore()
    private let notifications = FakeNotifications()
    private let feedback = FakeFeedback()
    private let permissions = FakePermissions()

    private func makeModel(rest: Int = 60) -> WorkoutSessionViewModel {
        var exercise = SampleData.exercise(sets: [
            SampleData.set(isCompleted: false),
            SampleData.set(reps: 8, load: .kilograms(30), isCompleted: false),
        ])
        exercise.restSeconds = rest
        let clock = clock
        let session = SampleData.session(startedAt: clock.now, status: .active, exercises: [exercise])
        return WorkoutSessionViewModel(
            session: session,
            repository: repository,
            exporter: HealthExporter(health: health, sessions: repository, activities: InMemoryActivitySessionRepository()),
            notifications: notifications,
            feedback: feedback,
            permissions: permissions,
            settings: AppSettings(store: store),
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
        #expect(!model.isFinishing)
    }

    @Test func cameraRepsFillTheNextOpenSet() {
        let model = makeModel()
        let exerciseID = model.session.exercises[0].id
        model.addCameraSet(exerciseID: exerciseID, reps: 15)
        let first = model.session.exercises[0].sets[0]
        #expect(first.reps == 15)
        #expect(first.isCompleted)
        #expect(first.source == .camera)
        model.addCameraSet(exerciseID: exerciseID, reps: 12)
        model.addCameraSet(exerciseID: exerciseID, reps: 9)
        let sets = model.session.exercises[0].sets
        #expect(sets.count == 3)
        #expect(sets.map(\.reps) == [15, 12, 9])
        #expect(sets[2].load == .kilograms(30))
    }

    @Test func onlySupportedExercisesOfferCameraCounting() {
        let model = makeModel()
        #expect(model.cameraExercise(for: SampleData.exercise(name: "Bodyweight squat")) == .squat)
        #expect(model.cameraExercise(for: SampleData.exercise(name: "Bench press")) == nil)
    }

    @Test func finishedWorkoutIsSavedToHealthWhenEnabled() async {
        var preferences = UserPreferences.standard
        preferences.exportsToHealth = true
        store.save(preferences, ownerID: LocalProfile.ownerID)
        let model = makeModel()
        clock.advance(by: 600)
        model.finish()
        #expect(await eventually { model.isFinished && health.saveAttempts == 1 })
        let saved = await eventuallyValue { () async -> WorkoutSession? in
            let stored = await repository.stored(id: model.session.id)
            return stored?.healthExport == .exported ? stored : nil
        }
        #expect(saved != nil)
    }

    @Test func workoutsStayLocalWhenHealthExportIsOff() async {
        let model = makeModel()
        model.finish()
        #expect(await eventually { model.isFinished })
        #expect(health.saveAttempts == 0)
    }

    @Test func restSchedulesAnAlertForWhenItEnds() async {
        let model = makeModel(rest: 90)
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        let alerts = await eventuallyValue { () async -> [Date]? in
            let alerts = await notifications.restAlerts
            return alerts.isEmpty ? nil : alerts
        }
        #expect(alerts == [clock.now.addingTimeInterval(90)])
    }

    @Test func skippingRestCancelsTheAlert() async {
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.skipRest()
        let cancels = await eventuallyValue { () async -> Int? in
            let count = await notifications.restCancelCount
            return count > 0 ? count : nil
        }
        #expect(cancels == 1)
    }

    @Test func restAlertsCanBeTurnedOff() async {
        var preferences = UserPreferences.standard
        preferences.restAlertsEnabled = false
        store.save(preferences, ownerID: LocalProfile.ownerID)
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(await notifications.restAlerts.isEmpty)
    }

    @Test func finishingShowsNewPersonalRecords() async throws {
        let earlier = SampleData.session(
            startedAt: SampleData.daysAgo(7),
            exercises: [SampleData.exercise(sets: [SampleData.set(reps: 10, load: .kilograms(20))])]
        )
        try await repository.save(earlier)
        let model = makeModel()
        let exercise = model.session.exercises[0]
        model.toggleCompletion(exerciseID: exercise.id, setID: exercise.sets[1].id)
        clock.advance(by: 300)
        model.finish()
        #expect(await eventually { model.finishSummary != nil })
        let records = model.finishSummary?.records ?? []
        #expect(records.map(\.kind) == [.heaviestLoad])
        #expect(records.first?.value == 30)
        #expect(model.finishSummary?.completedSets == 1)
    }

    @Test func finishingTwiceSavesOnce() async {
        let model = makeModel()
        model.finish()
        model.finish()
        #expect(await eventually { model.finishSummary != nil })
        #expect(await repository.saveCount == 1)
    }

    @Test func restThatEndedWhileAwayIsCleared() {
        let model = makeModel(rest: 60)
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.disappear()
        #expect(model.restEndsAt != nil)
        clock.advance(by: 120)
        model.start()
        #expect(model.restEndsAt == nil)
    }

    @Test func restStillRunningWhenYouComeBackIsKept() {
        let model = makeModel(rest: 60)
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        let end = model.restEndsAt
        model.disappear()
        clock.advance(by: 20)
        model.start()
        #expect(model.restEndsAt == end)
    }

    @Test func onlyWorkoutsWithDoneSetsCanBeSaved() {
        let model = makeModel()
        #expect(!model.hasCompletedSets)
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        #expect(model.hasCompletedSets)
    }

    @Test func discardingDeletesTheWorkout() async {
        let model = makeModel()
        model.start()
        let started = await eventuallyValue { await repository.stored(id: model.session.id) }
        #expect(started != nil)
        model.discard()
        #expect(await eventually { model.isDiscarded })
        #expect(await repository.stored(id: model.session.id) == nil)
        #expect(model.finishSummary == nil)
    }

    @Test func restAlertPermissionIsAskedForOnce() async {
        let model = makeModel()
        model.start()
        #expect(await eventually { permissions.requested == [.notifications] })
        model.start()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(permissions.requested == [.notifications])
    }

    @Test func noPermissionPromptWhenRestAlertsAreOff() async {
        var preferences = UserPreferences.standard
        preferences.restAlertsEnabled = false
        store.save(preferences, ownerID: LocalProfile.ownerID)
        let model = makeModel()
        model.start()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(permissions.requested.isEmpty)
    }

    @Test func turningBodyweightOffRestoresALoadFromTheExercise() {
        let model = makeModel()
        let exercise = model.session.exercises[0]
        let first = exercise.sets[0].id
        model.setBodyweight(exerciseID: exercise.id, setID: first, isOn: true)
        #expect(model.session.exercises[0].sets[0].load == .bodyweight)
        model.setBodyweight(exerciseID: exercise.id, setID: first, isOn: false)
        #expect(model.session.exercises[0].sets[0].load == .kilograms(30))
    }

    @Test func aWorkoutLeftOpenCanFinishAtItsLastSet() async {
        let model = makeModel()
        let ids = firstSet(model)
        clock.advance(by: 600)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        let lastSet = clock.now
        model.disappear()
        clock.advance(by: 5 * 3_600)
        model.start()
        #expect(model.isAskingAboutStaleSession)
        #expect(model.lastSetTimeText != nil)
        model.finishAtLastSet()
        #expect(await eventually { model.isFinished })
        let saved = await repository.stored(id: model.session.id)
        #expect(saved?.endedAt == lastSet)
        #expect(saved?.activeSeconds == 600)
    }

    @Test func aRecentWorkoutDoesNotAsk() {
        let model = makeModel()
        clock.advance(by: 3_600)
        model.start()
        #expect(!model.isAskingAboutStaleSession)
    }

    @Test func lastTimeIsShownForEachExercise() async throws {
        try await repository.save(SampleData.session(
            startedAt: SampleData.daysAgo(3),
            exercises: [SampleData.exercise(sets: [SampleData.set(reps: 12, load: .kilograms(25))])]
        ))
        let model = makeModel()
        model.start()
        let exercise = model.session.exercises[0]
        #expect(await eventually { model.lastTimeText(for: exercise) == "Last time: 1 × 12 · 25 kg" })
    }

    @Test func completingSetsGivesFeedback() {
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.addCameraSet(exerciseID: ids.exercise, reps: 12)
        #expect(feedback.completedSets == 2)
    }

    @Test func undoingASetGivesNoFeedback() {
        let model = makeModel()
        let ids = firstSet(model)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        model.toggleCompletion(exerciseID: ids.exercise, setID: ids.set)
        #expect(feedback.completedSets == 1)
    }
}
