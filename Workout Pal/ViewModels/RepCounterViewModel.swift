import AVFoundation
import Foundation
import Observation

enum CameraState: Equatable {
    case idle
    case starting
    case running
    case denied
    case unavailable
    case failed(String)
}

@MainActor
@Observable
final class RepCounterViewModel {
    let exercises = CameraExercise.allCases
    let canChangeExercise: Bool

    private(set) var exercise: CameraExercise?
    private(set) var cameraState: CameraState = .idle
    private(set) var latestFrame: PoseFrame?
    private(set) var trackingStatus: TrackingStatus = .searching
    private(set) var isCounting = false
    private(set) var detectedReps = 0
    private(set) var countingHint = ""

    private let camera: any PoseDetecting
    private let permissions: any PermissionsProviding
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var counter: RepCounter?

    init(camera: any PoseDetecting, permissions: any PermissionsProviding, exercise: CameraExercise? = nil) {
        self.camera = camera
        self.permissions = permissions
        self.exercise = exercise
        canChangeExercise = exercise == nil
    }

    var captureSession: AVCaptureSession {
        camera.captureSession
    }

    var isCameraActive: Bool {
        cameraState == .starting || cameraState == .running
    }

    var canStartCounting: Bool {
        cameraState == .running && !isCounting
    }

    func select(_ exercise: CameraExercise) {
        self.exercise = exercise
    }

    func changeExercise() {
        guard canChangeExercise else {
            return
        }
        stopCamera()
        exercise = nil
    }

    func startCamera() {
        guard exercise != nil, !isCameraActive else {
            return
        }
        cameraState = .starting
        streamTask = Task {
            let access = await self.permissions.request(.camera)
            guard !Task.isCancelled else {
                return
            }
            switch access {
            case .granted:
                await self.runCamera()
            case .unavailable:
                self.cameraState = .unavailable
            default:
                self.cameraState = .denied
            }
        }
    }

    func startCounting() {
        guard let exercise, canStartCounting else {
            return
        }
        let counter = RepCounter(exercise: exercise)
        self.counter = counter
        detectedReps = 0
        countingHint = counter.hint
        isCounting = true
    }

    func stopCounting() {
        isCounting = false
        counter = nil
    }

    func stopCamera() {
        stopCounting()
        streamTask?.cancel()
        streamTask = nil
        camera.stop()
        latestFrame = nil
        trackingStatus = .searching
        if isCameraActive {
            cameraState = .idle
        }
    }

    func scenePhaseChanged(isActive: Bool) {
        if isActive {
            startCamera()
        } else {
            stopCamera()
        }
    }

    private func runCamera() async {
        do {
            let frames = try await camera.start()
            cameraState = .running
            for await frame in frames {
                handle(frame)
            }
        } catch {
            cameraState = .failed(error.localizedDescription)
        }
    }

    private func handle(_ frame: PoseFrame) {
        guard let exercise else {
            return
        }
        latestFrame = frame
        guard isCounting, var counter else {
            trackingStatus = exercise.trackingStatus(for: frame)
            return
        }
        counter.process(frame)
        self.counter = counter
        trackingStatus = counter.status
        detectedReps = counter.count
        countingHint = counter.hint
    }
}
