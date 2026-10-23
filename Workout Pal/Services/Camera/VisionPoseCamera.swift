import AVFoundation
import CoreMedia
import CoreVideo
import Foundation
import Vision

enum PoseCameraError: Error, LocalizedError {
    case unavailable
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "This device has no camera that can be used for counting."
        case .configurationFailed:
            "The camera could not be set up. Close other apps using the camera and try again."
        }
    }
}

final class VisionPoseCamera: NSObject, PoseDetecting, @unchecked Sendable {
    let captureSession = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "WorkoutPal.camera.session")
    private let videoQueue = DispatchQueue(label: "WorkoutPal.camera.video")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let lock = NSLock()
    private var continuation: AsyncStream<PoseFrame>.Continuation?
    private var isConfigured = false
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?

    func start() async throws -> AsyncStream<PoseFrame> {
        let (stream, continuation) = AsyncStream.makeStream(of: PoseFrame.self, bufferingPolicy: .bufferingNewest(1))
        replaceContinuation(with: continuation)
        try await withCheckedThrowingContinuation { (started: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.configureIfNeeded()
                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                    started.resume()
                } catch {
                    started.resume(throwing: error)
                }
            }
        }
        return stream
    }

    func stop() {
        replaceContinuation(with: nil)
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func replaceContinuation(with newValue: AsyncStream<PoseFrame>.Continuation?) {
        lock.lock()
        let previous = continuation
        continuation = newValue
        lock.unlock()
        previous?.finish()
    }

    private func currentContinuation() -> AsyncStream<PoseFrame>.Continuation? {
        lock.lock()
        defer { lock.unlock() }
        return continuation
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else {
            return
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw PoseCameraError.unavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        }
        guard captureSession.canAddInput(input) else {
            throw PoseCameraError.configurationFailed
        }
        captureSession.addInput(input)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard captureSession.canAddOutput(videoOutput) else {
            throw PoseCameraError.configurationFailed
        }
        captureSession.addOutput(videoOutput)
        if let connection = videoOutput.connection(with: .video), connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = device.position == .front
        }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
        rotationCoordinator = coordinator
        applyRotation(coordinator.videoRotationAngleForHorizonLevelCapture)
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: [.new]) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelCapture
            self?.sessionQueue.async { [weak self] in
                self?.applyRotation(angle)
            }
        }
        isConfigured = true
    }

    private func applyRotation(_ angle: CGFloat) {
        guard let connection = videoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(angle) else {
            return
        }
        connection.videoRotationAngle = angle
    }

    private static func joints(from observation: VNHumanBodyPoseObservation?) -> [BodyJoint: PosePoint] {
        guard let observation, let points = try? observation.recognizedPoints(.all) else {
            return [:]
        }
        var joints: [BodyJoint: PosePoint] = [:]
        for joint in BodyJoint.allCases {
            guard let point = points[jointName(for: joint)], point.confidence > 0 else {
                continue
            }
            joints[joint] = PosePoint(
                x: Double(point.location.x),
                y: 1 - Double(point.location.y),
                confidence: Double(point.confidence)
            )
        }
        return joints
    }

    private static func jointName(for joint: BodyJoint) -> VNHumanBodyPoseObservation.JointName {
        switch joint {
        case .nose: .nose
        case .neck: .neck
        case .leftShoulder: .leftShoulder
        case .rightShoulder: .rightShoulder
        case .leftElbow: .leftElbow
        case .rightElbow: .rightElbow
        case .leftWrist: .leftWrist
        case .rightWrist: .rightWrist
        case .root: .root
        case .leftHip: .leftHip
        case .rightHip: .rightHip
        case .leftKnee: .leftKnee
        case .rightKnee: .rightKnee
        case .leftAnkle: .leftAnkle
        case .rightAnkle: .rightAnkle
        }
    }
}

extension VisionPoseCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let continuation = currentContinuation(),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([request])
        } catch {
            return
        }
        let width = Double(CVPixelBufferGetWidth(pixelBuffer))
        let height = Double(CVPixelBufferGetHeight(pixelBuffer))
        let frame = PoseFrame(
            joints: Self.joints(from: request.results?.first),
            timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds,
            aspectRatio: height > 0 ? width / height : 1
        )
        continuation.yield(frame)
    }
}
