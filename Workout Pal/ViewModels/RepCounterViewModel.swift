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

enum RepCounterMode: Equatable {
    case standalone
    case workoutSet
}

@MainActor
@Observable
final class RepCounterViewModel {
    let exercises = CameraExercise.allCases
    let mode: RepCounterMode
    let canChangeExercise: Bool

    private(set) var exercise: CameraExercise?
    private(set) var cameraState: CameraState = .idle
    private(set) var latestFrame: PoseFrame?
    private(set) var trackingStatus: TrackingStatus = .searching
    private(set) var isCounting = false
    private(set) var detectedReps = 0
    private(set) var countingHint = ""
    private(set) var isReviewing = false
    private(set) var savedSession: WorkoutSession?
    private(set) var acceptedReps: Int?
    private(set) var errorMessage: String?
    var reviewedReps = 0

    private let camera: any PoseDetecting
    private let permissions: any PermissionsProviding
    private let sessions: any WorkoutSessionRepository
    private let settings: AppSettings
    private let now: @MainActor () -> Date
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var counter: RepCounter?
    @ObservationIgnored private var countingStartedAt: Date?

    init(
        camera: any PoseDetecting,
        permissions: any PermissionsProviding,
        sessions: any WorkoutSessionRepository,
        settings: AppSettings,
        exercise: CameraExercise? = nil,
        mode: RepCounterMode = .standalone,
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.camera = camera
        self.permissions = permissions
        self.sessions = sessions
        self.settings = settings
        self.exercise = exercise
        self.mode = mode
        self.now = now
        canChangeExercise = exercise == nil && mode == .standalone
    }

    var captureSession: AVCaptureSession {
        camera.captureSession
    }

    var isCameraActive: Bool {
        cameraState == .starting || cameraState == .running
    }

    var canStartCounting: Bool {
        cameraState == .running && !isCounting && !isReviewing
    }

    var savedSets: [WorkoutSet] {
        savedSession?.exercises.first?.sets ?? []
    }

    var acceptTitle: String {
        reviewedReps == 1 ? "Save 1 rep" : "Save \(reviewedReps) reps"
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    func select(_ exercise: CameraExercise) {
        self.exercise = exercise
    }

    func changeExercise() {
        guard canChangeExercise else {
            return
        }
        stopCamera()
        isReviewing = false
        savedSession = nil
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

    func startCounting() {
        guard let exercise, canStartCounting else {
            return
        }
        let counter = RepCounter(exercise: exercise)
        self.counter = counter
        detectedReps = 0
        countingHint = counter.hint
        countingStartedAt = now()
        isCounting = true
    }

    func stopCounting() {
        guard isCounting else {
            return
        }
        isCounting = false
        counter = nil
        reviewedReps = detectedReps
        isReviewing = true
    }

    func discardReview() {
        isReviewing = false
        detectedReps = 0
    }

    func acceptReps() {
        guard isReviewing, reviewedReps > 0 else {
            return
        }
        isReviewing = false
        switch mode {
        case .workoutSet:
            acceptedReps = reviewedReps
        case .standalone:
            saveSet(reps: reviewedReps)
        }
        detectedReps = 0
    }

    private func saveSet(reps: Int) {
        guard let exercise else {
            return
        }
        let end = now()
        let start = countingStartedAt ?? end
        let set = WorkoutSet(id: UUID(), reps: reps, load: .bodyweight, isCompleted: true, completedAt: end, source: .camera)
        var session = savedSession ?? WorkoutSession(
            id: UUID(),
            ownerID: settings.ownerID,
            routineID: nil,
            routineName: "\(exercise.title) · camera",
            startedAt: start,
            endedAt: end,
            activeSeconds: 0,
            status: .completed,
            notes: "",
            exercises: [
                SessionExercise(id: UUID(), exerciseID: exercise.exerciseID, exerciseName: exercise.title, restSeconds: 0, sets: []),
            ]
        )
        session.exercises[0].sets.append(set)
        session.endedAt = end
        session.activeSeconds += max(0, end.timeIntervalSince(start))
        savedSession = session
        let snapshot = session
        Task {
            do {
                try await self.sessions.save(snapshot)
            } catch {
                self.errorMessage = error.localizedDescription
            }
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
