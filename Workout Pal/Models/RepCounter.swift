import Foundation

enum RepPhase: Equatable, Sendable {
    case waitingForStart
    case rest
    case active
}

struct RepCounter: Sendable {
    static let lostFrameLimit = 8
    static let minimumMovementSeconds: TimeInterval = 0.15
    static let smoothing = 0.5

    enum Position {
        case rest
        case active
        case between
    }

    let exercise: CameraExercise
    private(set) var count = 0
    private(set) var phase: RepPhase = .waitingForStart
    private(set) var status: TrackingStatus = .searching
    private var smoothedSignal: Double?
    private var lostFrames = 0
    private var phaseChangedAt: TimeInterval = 0

    init(exercise: CameraExercise) {
        self.exercise = exercise
    }

    var hint: String {
        switch phase {
        case .waitingForStart:
            switch exercise {
            case .squat: "Stand up tall to start."
            case .jumpingJack: "Stand with your feet together and arms down to start."
            }
        case .rest, .active:
            "Counting. Keep going at your own pace."
        }
    }

    mutating func process(_ frame: PoseFrame) {
        status = exercise.trackingStatus(for: frame)
        guard status.isTracking, let position = position(in: frame) else {
            loseTracking()
            return
        }
        lostFrames = 0
        switch (phase, position) {
        case (.waitingForStart, .rest):
            enter(.rest, at: frame.timestamp)
        case (.rest, .active):
            enter(.active, at: frame.timestamp)
        case (.active, .rest):
            if frame.timestamp - phaseChangedAt >= Self.minimumMovementSeconds {
                count += 1
            }
            enter(.rest, at: frame.timestamp)
        default:
            break
        }
    }

    private mutating func enter(_ newPhase: RepPhase, at time: TimeInterval) {
        phase = newPhase
        phaseChangedAt = time
    }

    private mutating func loseTracking() {
        lostFrames += 1
        if lostFrames >= Self.lostFrameLimit {
            phase = .waitingForStart
            smoothedSignal = nil
        }
    }

    private mutating func smoothed(_ value: Double) -> Double {
        let next = smoothedSignal.map { $0 + Self.smoothing * (value - $0) } ?? value
        smoothedSignal = next
        return next
    }

    private mutating func position(in frame: PoseFrame) -> Position? {
        switch exercise {
        case .squat:
            guard let angle = Self.kneeAngle(in: frame) else {
                return nil
            }
            let knee = smoothed(angle)
            if knee >= SquatThresholds.standing {
                return .rest
            }
            return knee <= SquatThresholds.bottom ? .active : .between
        case .jumpingJack:
            return nil
        }
    }

    static func kneeAngle(in frame: PoseFrame) -> Double? {
        let legs: [(hip: BodyJoint, knee: BodyJoint, ankle: BodyJoint)] = [
            (.leftHip, .leftKnee, .leftAnkle),
            (.rightHip, .rightKnee, .rightAnkle),
        ]
        let angles = legs.compactMap { leg -> Double? in
            guard let hip = frame.position(leg.hip),
                  let knee = frame.position(leg.knee),
                  let ankle = frame.position(leg.ankle)
            else {
                return nil
            }
            return PoseGeometry.angle(at: knee, hip, ankle)
        }
        guard !angles.isEmpty else {
            return nil
        }
        return angles.reduce(0, +) / Double(angles.count)
    }
}

enum SquatThresholds {
    static let standing = 160.0
    static let bottom = 115.0
}
