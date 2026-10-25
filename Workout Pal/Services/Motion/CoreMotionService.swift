import CoreMotion
import Foundation

struct CoreMotionService: MotionTracking {
    private final class Sensors: @unchecked Sendable {
        let pedometer = CMPedometer()
        let activityManager = CMMotionActivityManager()
        let queue = OperationQueue()
    }

    func capabilities() -> MotionCapabilities {
        MotionCapabilities(
            canCountSteps: CMPedometer.isStepCountingAvailable(),
            canMeasureDistance: CMPedometer.isDistanceAvailable(),
            canDetectActivity: CMMotionActivityManager.isActivityAvailable()
        )
    }

    func readings(from start: Date) -> AsyncThrowingStream<PedometerReading, Error> {
        AsyncThrowingStream { continuation in
            let sensors = Sensors()
            sensors.pedometer.startUpdates(from: start) { @Sendable data, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let data {
                    continuation.yield(Self.reading(from: data))
                }
            }
            continuation.onTermination = { @Sendable _ in
                sensors.pedometer.stopUpdates()
            }
        }
    }

    func activities() -> AsyncStream<DetectedMotion> {
        AsyncStream { continuation in
            guard CMMotionActivityManager.isActivityAvailable() else {
                continuation.finish()
                return
            }
            let sensors = Sensors()
            sensors.activityManager.startActivityUpdates(to: sensors.queue) { @Sendable activity in
                if let activity {
                    continuation.yield(Self.motion(from: activity))
                }
            }
            continuation.onTermination = { @Sendable _ in
                sensors.activityManager.stopActivityUpdates()
            }
        }
    }

    func reading(from start: Date, to end: Date) async throws -> PedometerReading {
        guard end > start else {
            return .zero
        }
        let sensors = Sensors()
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PedometerReading, Error>) in
            sensors.pedometer.queryPedometerData(from: start, to: end) { @Sendable data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data.map { Self.reading(from: $0) } ?? .zero)
                }
            }
        }
        Self.keepAlive(sensors)
        return result
    }

    private static func keepAlive(_ object: AnyObject) {
        withExtendedLifetime(object) {}
    }

    private static func reading(from data: CMPedometerData) -> PedometerReading {
        PedometerReading(steps: data.numberOfSteps.intValue, distanceMeters: data.distance?.doubleValue)
    }

    private static func motion(from activity: CMMotionActivity) -> DetectedMotion {
        if activity.confidence == .low {
            return .unknown
        }
        if activity.running {
            return .running
        }
        if activity.walking {
            return .walking
        }
        if activity.cycling {
            return .cycling
        }
        if activity.automotive {
            return .automotive
        }
        return activity.stationary ? .stationary : .unknown
    }
}
