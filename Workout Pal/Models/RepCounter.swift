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
    private var smoothedSignals: SIMD2<Double>?
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
            smoothedSignals = nil
        }
    }

    private mutating func smoothed(_ value: SIMD2<Double>) -> SIMD2<Double> {
        let next = smoothedSignals.map { $0 + Self.smoothing * (value - $0) } ?? value
        smoothedSignals = next
        return next
    }

    private mutating func position(in frame: PoseFrame) -> Position? {
        switch exercise {
        case .squat:
            guard let angle = Self.kneeAngle(in: frame) else {
                return nil
            }
            let knee = smoothed(SIMD2(angle, 0)).x
            if knee >= SquatThresholds.standing {
                return .rest
            }
            return knee <= SquatThresholds.bottom ? .active : .between
        case .jumpingJack:
            guard let signals = Self.jumpingJackSignals(in: frame) else {
                return nil
            }
            let values = smoothed(signals)
            let arms = values.x
            let feet = values.y
            if arms >= JumpingJackThresholds.armsUp && feet >= JumpingJackThresholds.feetApart {
                return .active
            }
            if arms <= JumpingJackThresholds.armsDown && feet <= JumpingJackThresholds.feetTogether {
                return .rest
            }
            return .between
        }
    }

    static func jumpingJackSignals(in frame: PoseFrame) -> SIMD2<Double>? {
        guard let leftShoulder = frame.position(.leftShoulder),
              let rightShoulder = frame.position(.rightShoulder),
              let leftWrist = frame.position(.leftWrist),
              let rightWrist = frame.position(.rightWrist),
              let leftHip = frame.position(.leftHip),
              let rightHip = frame.position(.rightHip),
              let leftAnkle = frame.position(.leftAnkle),
              let rightAnkle = frame.position(.rightAnkle)
        else {
            return nil
        }
        let shoulders = PoseGeometry.midpoint(leftShoulder, rightShoulder)
        let hips = PoseGeometry.midpoint(leftHip, rightHip)
        let torso = PoseGeometry.distance(shoulders, hips)
        let shoulderWidth = PoseGeometry.distance(leftShoulder, rightShoulder)
        guard torso > 0, shoulderWidth > 0 else {
            return nil
        }
        let up = (shoulders - hips) / torso
        let leftHeight = ((leftWrist - shoulders) * up).sum()
        let rightHeight = ((rightWrist - shoulders) * up).sum()
        let arms = (leftHeight + rightHeight) / 2 / torso
        let feet = PoseGeometry.distance(leftAnkle, rightAnkle) / shoulderWidth
        return SIMD2(arms, feet)
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

enum JumpingJackThresholds {
    static let armsUp = 0.2
    static let armsDown = -0.4
    static let feetApart = 1.3
    static let feetTogether = 1.0
}
