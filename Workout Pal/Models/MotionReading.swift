struct MotionCapabilities: Hashable, Sendable {
    var canCountSteps: Bool
    var canMeasureDistance: Bool
    var canDetectActivity: Bool

    static let none = MotionCapabilities(canCountSteps: false, canMeasureDistance: false, canDetectActivity: false)
}

struct PedometerReading: Hashable, Sendable {
    var steps: Int
    var distanceMeters: Double?

    static let zero = PedometerReading(steps: 0, distanceMeters: nil)

    func adding(_ other: PedometerReading) -> PedometerReading {
        let distance: Double? = switch (distanceMeters, other.distanceMeters) {
        case let (first?, second?): first + second
        case let (first?, nil): first
        case let (nil, second?): second
        case (nil, nil): nil
        }
        return PedometerReading(steps: steps + other.steps, distanceMeters: distance)
    }
}

enum MotionSummary {
    static func dominantMotion(_ counts: [DetectedMotion: Int]) -> DetectedMotion? {
        let moving = counts.filter { $0.key != .unknown && $0.key != .stationary }
        if let best = moving.max(by: { $0.value < $1.value }) {
            return best.key
        }
        if counts[.stationary, default: 0] > 0 {
            return .stationary
        }
        return counts.isEmpty ? nil : .unknown
    }
}
