import Testing
@testable import Workout_Pal

struct MotionReadingTests {
    @Test func addingReadingsSumsStepsAndAvailableDistance() {
        let first = PedometerReading(steps: 100, distanceMeters: 80)
        let second = PedometerReading(steps: 50, distanceMeters: nil)
        #expect(first.adding(second) == PedometerReading(steps: 150, distanceMeters: 80))
        #expect(PedometerReading.zero.adding(.zero).distanceMeters == nil)
    }

    @Test func dominantMotionPrefersMovement() {
        let counts: [DetectedMotion: Int] = [.stationary: 9, .walking: 4, .running: 2, .unknown: 12]
        #expect(MotionSummary.dominantMotion(counts) == .walking)
    }

    @Test func standingStillOnlyIsReported() {
        #expect(MotionSummary.dominantMotion([.stationary: 3, .unknown: 1]) == .stationary)
    }

    @Test func noReadingsMeansNoMotion() {
        #expect(MotionSummary.dominantMotion([:]) == nil)
        #expect(MotionSummary.dominantMotion([.unknown: 2]) == .unknown)
    }

    @Test func distanceFollowsTheUnitPreference() {
        #expect(Formatting.distance(meters: 0, units: .kilograms).hasSuffix("km"))
        #expect(Formatting.distance(meters: 0, units: .pounds).hasSuffix("mi"))
    }
}
