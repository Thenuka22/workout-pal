import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct ActivityTrackerViewModelTests {
    private let clock = TestClock(SampleData.now)
    private let motion = FakeMotion()
    private let permissions = FakePermissions()

    private func makeModel() -> ActivityTrackerViewModel {
        let clock = clock
        return ActivityTrackerViewModel(
            motion: motion,
            permissions: permissions,
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

    @Test func discardingClearsTheSession() async {
        let model = makeModel()
        #expect(await started(model))
        model.discard()
        #expect(model.activity == nil)
        #expect(model.steps == 0)
    }
}
