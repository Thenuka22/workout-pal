import Foundation
@testable import Workout_Pal

enum PoseFixtures {
    static func frame(
        _ joints: [BodyJoint: SIMD2<Double>],
        time: TimeInterval = 0,
        confidence: Double = 0.9
    ) -> PoseFrame {
        PoseFrame(
            joints: joints.mapValues { PosePoint(x: $0.x, y: $0.y, confidence: confidence) },
            timestamp: time,
            aspectRatio: 1
        )
    }

    static func squat(kneeAngle degrees: Double, time: TimeInterval = 0) -> PoseFrame {
        let radians = degrees * .pi / 180
        let knee = SIMD2(0.5, 0.7)
        let ankle = SIMD2(0.5, 0.9)
        let hip = knee + 0.2 * SIMD2(sin(radians), cos(radians))
        let shoulder = hip + SIMD2(0, -0.25)
        return frame([
            .leftShoulder: shoulder, .rightShoulder: shoulder,
            .leftHip: hip, .rightHip: hip,
            .leftKnee: knee, .rightKnee: knee,
            .leftAnkle: ankle, .rightAnkle: ankle,
        ], time: time)
    }

    static func jumpingJack(open: Bool, time: TimeInterval = 0) -> PoseFrame {
        let shoulderY = 0.35
        let hipY = 0.6
        let wristY = open ? 0.15 : 0.62
        let wristX = open ? 0.18 : 0.08
        let ankleX = open ? 0.16 : 0.03
        return frame([
            .neck: SIMD2(0.5, 0.32),
            .leftShoulder: SIMD2(0.42, shoulderY), .rightShoulder: SIMD2(0.58, shoulderY),
            .leftWrist: SIMD2(0.5 - wristX, wristY), .rightWrist: SIMD2(0.5 + wristX, wristY),
            .leftHip: SIMD2(0.45, hipY), .rightHip: SIMD2(0.55, hipY),
            .leftKnee: SIMD2(0.5 - ankleX * 0.7, 0.75), .rightKnee: SIMD2(0.5 + ankleX * 0.7, 0.75),
            .leftAnkle: SIMD2(0.5 - ankleX, 0.9), .rightAnkle: SIMD2(0.5 + ankleX, 0.9),
        ], time: time)
    }

    static func removing(_ joints: [BodyJoint], from frame: PoseFrame) -> PoseFrame {
        var copy = frame
        for joint in joints {
            copy.joints[joint] = nil
        }
        return copy
    }

    static let empty = PoseFrame(joints: [:], timestamp: 0, aspectRatio: 1)
}
