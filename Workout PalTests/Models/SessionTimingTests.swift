import Foundation
import Testing
@testable import Workout_Pal

struct SessionTimingTests {
    private let start = SampleData.now

    private func at(_ seconds: Double) -> Date {
        start.addingTimeInterval(seconds)
    }

    @Test func activeTimeWithoutPausesIsWallClockTime() {
        let seconds = SessionTiming.activeSeconds(startedAt: start, endedAt: at(600), pauses: [])
        #expect(seconds == 600)
    }

    @Test func closedPausesAreSubtracted() {
        let pauses = [PauseInterval(start: at(100), end: at(160)), PauseInterval(start: at(300), end: at(330))]
        let seconds = SessionTiming.activeSeconds(startedAt: start, endedAt: at(600), pauses: pauses)
        #expect(seconds == 510)
    }

    @Test func openPauseStopsTheClock() {
        let pauses = [PauseInterval(start: at(200), end: nil)]
        let seconds = SessionTiming.activeSeconds(startedAt: start, endedAt: nil, pauses: pauses, now: at(900))
        #expect(seconds == 200)
        #expect(SessionTiming.isPaused(pauses))
    }

    @Test func activeIntervalsSkipPausedTime() {
        let pauses = [PauseInterval(start: at(100), end: at(160))]
        let intervals = SessionTiming.activeIntervals(startedAt: start, endedAt: at(400), pauses: pauses)
        #expect(intervals == [
            DateInterval(start: start, end: at(100)),
            DateInterval(start: at(160), end: at(400)),
        ])
    }

    @Test func pausingTwiceKeepsOnePause() {
        let once = SessionTiming.pausing([], at: at(50))
        let twice = SessionTiming.pausing(once, at: at(80))
        #expect(twice.count == 1)
        #expect(twice.first?.start == at(50))
    }

    @Test func resumingClosesTheOpenPause() {
        let paused = SessionTiming.pausing([], at: at(50))
        let resumed = SessionTiming.resuming(paused, at: at(90))
        #expect(resumed == [PauseInterval(start: at(50), end: at(90))])
        #expect(!SessionTiming.isPaused(resumed))
    }

    @Test func resumingWhenNotPausedChangesNothing() {
        let pauses = [PauseInterval(start: at(10), end: at(20))]
        #expect(SessionTiming.resuming(pauses, at: at(30)) == pauses)
    }

    @Test func pausesOutsideTheSessionAreIgnored() {
        let pauses = [PauseInterval(start: at(-100), end: at(-50)), PauseInterval(start: at(700), end: at(800))]
        let seconds = SessionTiming.activeSeconds(startedAt: start, endedAt: at(600), pauses: pauses)
        #expect(seconds == 600)
    }
}
