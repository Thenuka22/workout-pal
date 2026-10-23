import Foundation

enum BodyJoint: String, CaseIterable, Sendable {
    case nose
    case neck
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case root
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
}

struct PosePoint: Hashable, Sendable {
    var x: Double
    var y: Double
    var confidence: Double
}

struct PoseFrame: Sendable {
    static let minimumConfidence = 0.3

    var joints: [BodyJoint: PosePoint]
    var timestamp: TimeInterval
    var aspectRatio: Double

    var hasBody: Bool {
        joints.values.contains { $0.confidence >= Self.minimumConfidence }
    }

    func point(_ joint: BodyJoint) -> PosePoint? {
        guard let point = joints[joint], point.confidence >= Self.minimumConfidence else {
            return nil
        }
        return point
    }

    func position(_ joint: BodyJoint) -> SIMD2<Double>? {
        point(joint).map { SIMD2($0.x * aspectRatio, $0.y) }
    }

    func hasAll(_ required: [BodyJoint]) -> Bool {
        required.allSatisfy { point($0) != nil }
    }
}

struct PoseBone: Sendable {
    let from: BodyJoint
    let to: BodyJoint

    static let skeleton = [
        PoseBone(from: .leftShoulder, to: .rightShoulder),
        PoseBone(from: .leftShoulder, to: .leftElbow),
        PoseBone(from: .leftElbow, to: .leftWrist),
        PoseBone(from: .rightShoulder, to: .rightElbow),
        PoseBone(from: .rightElbow, to: .rightWrist),
        PoseBone(from: .neck, to: .root),
        PoseBone(from: .leftHip, to: .rightHip),
        PoseBone(from: .leftHip, to: .leftKnee),
        PoseBone(from: .leftKnee, to: .leftAnkle),
        PoseBone(from: .rightHip, to: .rightKnee),
        PoseBone(from: .rightKnee, to: .rightAnkle),
    ]
}

enum PoseGeometry {
    static func distance(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let delta = a - b
        return (delta * delta).sum().squareRoot()
    }

    static func midpoint(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SIMD2<Double> {
        (a + b) / 2
    }

    static func angle(at vertex: SIMD2<Double>, _ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let first = a - vertex
        let second = b - vertex
        let lengths = distance(a, vertex) * distance(b, vertex)
        guard lengths > 0 else {
            return 0
        }
        let cosine = min(max((first * second).sum() / lengths, -1), 1)
        return acos(cosine) * 180 / .pi
    }
}
