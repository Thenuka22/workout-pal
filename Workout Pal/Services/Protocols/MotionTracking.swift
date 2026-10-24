import Foundation

protocol MotionTracking: Sendable {
    func capabilities() -> MotionCapabilities
    func readings(from start: Date) -> AsyncThrowingStream<PedometerReading, Error>
    func activities() -> AsyncStream<DetectedMotion>
    func reading(from start: Date, to end: Date) async throws -> PedometerReading
}
