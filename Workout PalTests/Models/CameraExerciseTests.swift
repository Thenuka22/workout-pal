import Foundation
import Testing
@testable import Workout_Pal

struct CameraExerciseTests {
    @Test func emptyFrameMeansNobodyIsInView() {
        #expect(CameraExercise.squat.trackingStatus(for: nil) == .searching)
        #expect(CameraExercise.jumpingJack.trackingStatus(for: PoseFixtures.empty) == .searching)
    }

    @Test func squatsNeedOneWholeLeg() {
        let standing = PoseFixtures.squat(kneeAngle: 175)
        #expect(CameraExercise.squat.trackingStatus(for: standing) == .tracking)
        let oneLeg = PoseFixtures.removing([.leftAnkle, .leftKnee], from: standing)
        #expect(CameraExercise.squat.trackingStatus(for: oneLeg) == .tracking)
        let noFeet = PoseFixtures.removing([.leftAnkle, .rightAnkle], from: standing)
        #expect(!CameraExercise.squat.trackingStatus(for: noFeet).isTracking)
    }

    @Test func jumpingJacksNeedHandsAndFeet() {
        let pose = PoseFixtures.jumpingJack(open: false)
        #expect(CameraExercise.jumpingJack.trackingStatus(for: pose) == .tracking)
        let noHand = PoseFixtures.removing([.rightWrist], from: pose)
        #expect(CameraExercise.jumpingJack.trackingStatus(for: noHand) == .adjusting("Step back so both hands are in view."))
        let noFoot = PoseFixtures.removing([.leftAnkle], from: pose)
        #expect(CameraExercise.jumpingJack.trackingStatus(for: noFoot) == .adjusting("Step back so both feet are in view."))
    }

    @Test func lowConfidenceJointsDoNotCount() {
        let blurry = PoseFixtures.frame([.leftHip: SIMD2(0.5, 0.5)], confidence: 0.1)
        #expect(!blurry.hasBody)
        #expect(blurry.point(.leftHip) == nil)
    }

    @Test func matchesRoutineExerciseNames() {
        #expect(CameraExercise.matching(exerciseName: "Barbell Squat") == .squat)
        #expect(CameraExercise.matching(exerciseName: "Jumping Jacks") == .jumpingJack)
        #expect(CameraExercise.matching(exerciseName: "Star jumps") == .jumpingJack)
        #expect(CameraExercise.matching(exerciseName: "Bench press") == nil)
    }

    @Test func angleBetweenPerpendicularLimbsIsNinetyDegrees() {
        let angle = PoseGeometry.angle(at: SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1))
        #expect(abs(angle - 90) < 0.0001)
    }

    @Test func squatFixtureHasTheRequestedKneeAngle() throws {
        let frame = PoseFixtures.squat(kneeAngle: 100)
        let knee = try #require(frame.position(.leftKnee))
        let hip = try #require(frame.position(.leftHip))
        let ankle = try #require(frame.position(.leftAnkle))
        #expect(abs(PoseGeometry.angle(at: knee, hip, ankle) - 100) < 0.0001)
    }
}
