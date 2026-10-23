import Foundation
import Testing
@testable import Workout_Pal

struct RepCounterTests {
    private struct Script {
        var frames: [PoseFrame] = []
        var time: TimeInterval = 0

        mutating func add(_ make: (TimeInterval) -> PoseFrame, count: Int = 6) {
            for _ in 0..<count {
                frames.append(make(time))
                time += 0.1
            }
        }

        mutating func squat(_ angle: Double, count: Int = 6) {
            add({ PoseFixtures.squat(kneeAngle: angle, time: $0) }, count: count)
        }

        mutating func empty(count: Int) {
            add({ time in
                var frame = PoseFixtures.empty
                frame.timestamp = time
                return frame
            }, count: count)
        }
    }

    private func run(_ exercise: CameraExercise, _ script: Script) -> RepCounter {
        var counter = RepCounter(exercise: exercise)
        for frame in script.frames {
            counter.process(frame)
        }
        return counter
    }

    @Test func countsFullSquats() {
        var script = Script()
        script.squat(175)
        for _ in 0..<3 {
            script.squat(90)
            script.squat(175)
        }
        let counter = run(.squat, script)
        #expect(counter.count == 3)
        #expect(counter.phase == .rest)
    }

    @Test func halfSquatsDoNotCount() {
        var script = Script()
        script.squat(175)
        script.squat(135)
        script.squat(175)
        #expect(run(.squat, script).count == 0)
    }

    @Test func standingStillDoesNotCount() {
        var script = Script()
        script.squat(172, count: 40)
        #expect(run(.squat, script).count == 0)
    }

    @Test func aSingleGlitchyFrameIsSmoothedAway() {
        var script = Script()
        script.squat(175)
        script.squat(95, count: 1)
        script.squat(175)
        #expect(run(.squat, script).count == 0)
    }

    @Test func startingAtTheBottomWaitsForStanding() {
        var script = Script()
        script.squat(90)
        script.squat(175)
        let counter = run(.squat, script)
        #expect(counter.count == 0)
        #expect(counter.phase == .rest)
    }

    @Test func leavingTheFrameAtTheBottomDoesNotCount() {
        var script = Script()
        script.squat(175)
        script.squat(90)
        script.empty(count: RepCounter.lostFrameLimit + 2)
        script.squat(175)
        let counter = run(.squat, script)
        #expect(counter.count == 0)
    }

    @Test func briefTrackingLossKeepsTheRep() {
        var script = Script()
        script.squat(175)
        script.squat(90)
        script.empty(count: 2)
        script.squat(175)
        #expect(run(.squat, script).count == 1)
    }

    @Test func lostTrackingIsReported() {
        var script = Script()
        script.squat(175)
        script.empty(count: RepCounter.lostFrameLimit)
        let counter = run(.squat, script)
        #expect(counter.status == .searching)
        #expect(counter.phase == .waitingForStart)
    }
}
