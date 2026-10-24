import AVFoundation
@testable import Workout_Pal

final class FakePoseCamera: PoseDetecting, @unchecked Sendable {
    let captureSession = AVCaptureSession()
    private var continuation: AsyncStream<PoseFrame>.Continuation?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    var isStreaming: Bool {
        continuation != nil
    }

    func start() async throws -> AsyncStream<PoseFrame> {
        let (stream, continuation) = AsyncStream.makeStream(of: PoseFrame.self)
        self.continuation = continuation
        startCount += 1
        return stream
    }

    func stop() {
        stopCount += 1
        continuation?.finish()
        continuation = nil
    }

    func send(_ frames: [PoseFrame]) {
        for frame in frames {
            continuation?.yield(frame)
        }
    }
}
