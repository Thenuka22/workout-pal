import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct ActivityTrackerViewModelTests {
    private let clock = TestClock(SampleData.now)
    private let motion = FakeMotion()
    private let permissions = FakePermissions()
    private let repository = InMemoryActivitySessionRepository()

    private func makeModel() -> ActivityTrackerViewModel {
        let clock = clock
        return ActivityTrackerViewModel(
            motion: motion,
            permissions: permissions,
            activities: repository,
            exporter: HealthExporter(health: FakeHealthService(), sessions: InMemoryWorkoutSessionRepository(), activities: repository),
            settings: AppSettings(store: InMemoryPreferencesStore()),
            now: { clock.now }
        )
    }

    private func started(_ model: ActivityTrackerViewModel) async -> Bool {
        model.start()
        return await eventually { model.activity != nil && motion.isStreaming }
    }

    @Test func devicesWithoutAPedometerCannotStart() {
        motion.available = .none
        let model = makeModel()
        model.start()
        #expect(!model.isAvailable)
        #expect(model.activity == nil)
    }

    @Test func deniedMotionAccessIsShown() async {
        permissions.statusAfterRequest = .denied
        let model = makeModel()
        model.start()
        #expect(await eventually { model.motionAccess == .denied })
        #expect(model.isAccessBlocked)
        #expect(model.activity == nil)
    }

    @Test func liveReadingsShowSteps() async {
        let model = makeModel()
        model.kind = .run
        #expect(await started(model))
        #expect(model.activity?.kind == .run)
        motion.send(PedometerReading(steps: 120, distanceMeters: 95))
        #expect(await eventually { model.steps == 120 })
        #expect(model.distanceText != "Unavailable")
    }

    @Test func pausingKeepsStepsAndResumingStartsANewSegment() async {
        let model = makeModel()
        #expect(await started(model))
        motion.send(PedometerReading(steps: 100, distanceMeters: 70))
        #expect(await eventually { model.steps == 100 })
        clock.advance(by: 60)
        model.pause()
        #expect(model.isPaused)
        #expect(model.steps == 100)
        clock.advance(by: 120)
        model.resume()
        #expect(motion.readingStarts.last == clock.now)
        motion.send(PedometerReading(steps: 30, distanceMeters: 20))
        #expect(await eventually { model.steps == 130 })
        #expect(model.elapsedSeconds(at: clock.now) == 60)
    }

    @Test func finishingUsesMeasuredTotalsForActiveTimeOnly() async {
        motion.measure = { start, end in
            PedometerReading(steps: Int(end.timeIntervalSince(start)), distanceMeters: end.timeIntervalSince(start))
        }
        let model = makeModel()
        #expect(await started(model))
        motion.send(.walking)
        motion.send(.walking)
        motion.send(.running)
        #expect(await eventually { model.detectedMotion == .running })
        clock.advance(by: 300)
        model.pause()
        clock.advance(by: 600)
        model.resume()
        clock.advance(by: 100)
        model.finish()
        #expect(await eventually { model.finishedActivity != nil })
        let finished = model.finishedActivity
        #expect(finished?.steps == 400)
        #expect(finished?.distanceMeters == 400)
        #expect(finished?.activeSeconds == 400)
        #expect(finished?.detectedMotion == .walking)
        #expect(finished?.status == .completed)
        #expect(model.activity == nil)
    }

    @Test func missingDistanceIsReportedAsUnavailable() async {
        motion.available = MotionCapabilities(canCountSteps: true, canMeasureDistance: false, canDetectActivity: false)
        let model = makeModel()
        #expect(await started(model))
        #expect(model.distanceText == "Unavailable")
        #expect(model.detectedText == "Unavailable")
        model.finish()
        #expect(await eventually { model.finishedActivity != nil })
        #expect(model.finishedActivity?.distanceMeters == nil)
    }

    @Test func aFailedSaveCanBeRetried() async {
        let model = makeModel()
        #expect(await started(model))
        motion.send(PedometerReading(steps: 300, distanceMeters: 250))
        #expect(await eventually { model.steps == 300 })
        await repository.failSaves(with: CocoaError(.fileWriteUnknown))
        model.finish()
        #expect(await eventually { model.finishedActivity != nil && model.needsSaveRetry })
        #expect(model.errorTitle == "Couldn't save this session")
        let id = model.finishedActivity?.id ?? UUID()
        #expect(await repository.stored(id: id)?.status != .completed)
        await repository.failSaves(with: nil)
        model.retrySave()
        #expect(await eventually { !model.needsSaveRetry && !model.isFinishing })
        #expect(await repository.stored(id: id)?.status == .completed)
        #expect(model.errorMessage == nil)
    }

    @Test func discardingClearsTheSession() async {
        let model = makeModel()
        #expect(await started(model))
        model.discard()
        #expect(model.activity == nil)
        #expect(model.steps == 0)
    }

    @Test func startingSavesAnUnfinishedSession() async {
        let model = makeModel()
        #expect(await started(model))
        let id = model.activity?.id ?? UUID()
        let saved = await eventuallyValue { await repository.stored(id: id) }
        #expect(saved?.status == .active)
    }

    @Test func finishedSessionIsSavedAsCompleted() async {
        motion.measure = { _, _ in PedometerReading(steps: 800, distanceMeters: 600) }
        let model = makeModel()
        #expect(await started(model))
        clock.advance(by: 600)
        model.finish()
        #expect(await eventually { model.finishedActivity != nil })
        let id = model.finishedActivity?.id ?? UUID()
        let saved = await repository.stored(id: id)
        #expect(saved?.status == .completed)
        #expect(saved?.steps == 800)
        #expect(saved?.distanceMeters == 600)
    }

    @Test func unfinishedSessionIsRestoredAfterRelaunch() async {
        var paused = ActivitySession.start(kind: .run, ownerID: LocalProfile.ownerID, now: clock.now.addingTimeInterval(-900))
        paused.pauses = [PauseInterval(start: clock.now.addingTimeInterval(-300), end: nil)]
        paused.steps = 1_200
        try? await repository.save(paused)
        let model = makeModel()
        await model.load()
        #expect(model.activity?.id == paused.id)
        #expect(model.kind == .run)
        #expect(model.isPaused)
        #expect(model.steps == 1_200)
        #expect(model.elapsedSeconds(at: clock.now) == 600)
    }

    @Test func restoredRunningSessionResumesLiveUpdates() async {
        let running = ActivitySession.start(kind: .walk, ownerID: LocalProfile.ownerID, now: clock.now.addingTimeInterval(-120))
        try? await repository.save(running)
        let model = makeModel()
        await model.load()
        #expect(motion.readingStarts.last == running.startedAt)
        motion.send(PedometerReading(steps: 150, distanceMeters: nil))
        #expect(await eventually { model.steps == 150 })
    }

    @Test func discardingDeletesTheSavedSession() async {
        let model = makeModel()
        #expect(await started(model))
        let id = model.activity?.id ?? UUID()
        _ = await eventuallyValue { await repository.stored(id: id) }
        model.discard()
        #expect(await eventually { model.activity == nil })
        var stored: ActivitySession? = ActivitySession.start(kind: .walk, ownerID: "", now: .now)
        for _ in 0..<50 where stored != nil {
            stored = await repository.stored(id: id)
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(stored == nil)
    }
}
