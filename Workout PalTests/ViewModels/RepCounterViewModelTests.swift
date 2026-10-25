import Foundation
import Testing
@testable import Workout_Pal

@MainActor
struct RepCounterViewModelTests {
    private let camera = FakePoseCamera()
    private let permissions = FakePermissions()
    private let sessions = InMemoryWorkoutSessionRepository()

    private func makeModel(mode: RepCounterMode = .standalone) -> RepCounterViewModel {
        RepCounterViewModel(
            camera: camera,
            permissions: permissions,
            sessions: sessions,
            settings: AppSettings(store: InMemoryPreferencesStore()),
            exercise: .squat,
            mode: mode,
            now: { SampleData.now }
        )
    }

    private func oneSquat(startingAt start: TimeInterval = 0) -> [PoseFrame] {
        let angles = Array(repeating: 175.0, count: 6) + Array(repeating: 90.0, count: 6) + Array(repeating: 175.0, count: 6)
        return angles.enumerated().map { index, angle in
            PoseFixtures.squat(kneeAngle: angle, time: start + Double(index) * 0.1)
        }
    }

    private func startCounting(_ model: RepCounterViewModel) async -> Bool {
        model.startCamera()
        guard await eventually({ model.cameraState == .running && camera.isStreaming }) else {
            return false
        }
        model.startCounting()
        return model.isCounting
    }

    @Test func deniedCameraShowsTheDeniedState() async {
        permissions.statusAfterRequest = .denied
        let model = makeModel()
        model.startCamera()
        #expect(await eventually { model.cameraState == .denied })
        #expect(camera.startCount == 0)
    }

    @Test func framesWithoutCountingOnlyUpdateTracking() async {
        let model = makeModel()
        model.startCamera()
        #expect(await eventually { camera.isStreaming })
        camera.send([PoseFixtures.squat(kneeAngle: 175)])
        #expect(await eventually { model.trackingStatus == .tracking })
        #expect(model.detectedReps == 0)
    }

    @Test func countedRepsAreReviewedBeforeSaving() async {
        let model = makeModel()
        #expect(await startCounting(model))
        camera.send(oneSquat())
        #expect(await eventually { model.detectedReps == 1 })
        model.stopCounting()
        #expect(model.isReviewing)
        #expect(model.reviewedReps == 1)
        model.reviewedReps = 2
        model.acceptReps()
        let saved = model.savedSets
        #expect(saved.map(\.reps) == [2])
        #expect(saved.first?.source == .camera)
        let sessionID = model.savedSession?.id ?? UUID()
        let stored = await eventuallyValue { await sessions.stored(id: sessionID) }
        #expect(stored?.exercises.first?.exerciseID == CameraExercise.squat.exerciseID)
        #expect(stored?.status == .completed)
    }

    @Test func secondSetIsAddedToTheSameWorkout() async {
        let model = makeModel()
        #expect(await startCounting(model))
        camera.send(oneSquat())
        #expect(await eventually { model.detectedReps == 1 })
        model.stopCounting()
        model.acceptReps()
        model.startCounting()
        camera.send(oneSquat(startingAt: 10))
        #expect(await eventually { model.detectedReps == 1 })
        model.stopCounting()
        model.acceptReps()
        #expect(model.savedSets.count == 2)
    }

    @Test func workoutSetModeHandsTheRepsBack() async {
        let model = makeModel(mode: .workoutSet)
        #expect(!model.canChangeExercise)
        #expect(await startCounting(model))
        camera.send(oneSquat())
        #expect(await eventually { model.detectedReps == 1 })
        model.stopCounting()
        model.acceptReps()
        #expect(model.acceptedReps == 1)
        #expect(model.savedSession == nil)
    }

    @Test func discardingTheReviewSavesNothing() async {
        let model = makeModel()
        #expect(await startCounting(model))
        model.stopCounting()
        model.discardReview()
        #expect(!model.isReviewing)
        #expect(model.savedSets.isEmpty)
    }

    @Test func leavingTheScreenKeepsTheCountForReview() async {
        let model = makeModel()
        #expect(await startCounting(model))
        camera.send(oneSquat())
        #expect(await eventually { model.detectedReps == 1 })
        model.sceneDidEnterBackground()
        #expect(model.isReviewing)
        #expect(model.reviewedReps == 1)
        #expect(camera.stopCount > 0)
        #expect(model.cameraState == .idle)
    }
}
