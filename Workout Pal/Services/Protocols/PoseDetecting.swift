import AVFoundation

protocol PoseDetecting: AnyObject, Sendable {
    var captureSession: AVCaptureSession { get }
    func start() async throws -> AsyncStream<PoseFrame>
    func stop()
}
