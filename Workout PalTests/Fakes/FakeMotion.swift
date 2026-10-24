import Foundation
@testable import Workout_Pal

final class FakeMotion: MotionTracking, @unchecked Sendable {
    var available = MotionCapabilities(canCountSteps: true, canMeasureDistance: true, canDetectActivity: true)
    var measure: (Date, Date) -> PedometerReading = { _, _ in .zero }
    private(set) var readingStarts: [Date] = []
    private var readingContinuation: AsyncThrowingStream<PedometerReading, Error>.Continuation?
    private var motionContinuation: AsyncStream<DetectedMotion>.Continuation?

    var isStreaming: Bool {
        readingContinuation != nil
    }

    func capabilities() -> MotionCapabilities {
        available
    }

    func readings(from start: Date) -> AsyncThrowingStream<PedometerReading, Error> {
        readingStarts.append(start)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: PedometerReading.self, throwing: Error.self)
        readingContinuation = continuation
        return stream
    }

    func activities() -> AsyncStream<DetectedMotion> {
        let (stream, continuation) = AsyncStream.makeStream(of: DetectedMotion.self)
        motionContinuation = continuation
        return stream
    }

    func reading(from start: Date, to end: Date) async throws -> PedometerReading {
        measure(start, end)
    }

    func send(_ reading: PedometerReading) {
        readingContinuation?.yield(reading)
    }

    func send(_ motion: DetectedMotion) {
        motionContinuation?.yield(motion)
    }
}
