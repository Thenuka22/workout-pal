import Foundation

struct PauseInterval: Codable, Hashable, Sendable {
    var start: Date
    var end: Date?
}

enum SessionTiming {
    static func isPaused(_ pauses: [PauseInterval]) -> Bool {
        guard let last = pauses.last else {
            return false
        }
        return last.end == nil
    }

    static func activeIntervals(
        startedAt: Date,
        endedAt: Date?,
        pauses: [PauseInterval],
        now: Date = .now
    ) -> [DateInterval] {
        let end = max(endedAt ?? now, startedAt)
        var intervals: [DateInterval] = []
        var cursor = startedAt
        for pause in pauses.sorted(by: { $0.start < $1.start }) {
            let pauseStart = min(max(pause.start, cursor), end)
            if pauseStart > cursor {
                intervals.append(DateInterval(start: cursor, end: pauseStart))
            }
            cursor = min(max(pause.end ?? end, cursor), end)
        }
        if end > cursor {
            intervals.append(DateInterval(start: cursor, end: end))
        }
        return intervals
    }

    static func activeSeconds(
        startedAt: Date,
        endedAt: Date?,
        pauses: [PauseInterval],
        now: Date = .now
    ) -> Double {
        activeIntervals(startedAt: startedAt, endedAt: endedAt, pauses: pauses, now: now)
            .reduce(0) { $0 + $1.duration }
    }

    static func pausing(_ pauses: [PauseInterval], at date: Date) -> [PauseInterval] {
        guard !isPaused(pauses) else {
            return pauses
        }
        return pauses + [PauseInterval(start: date, end: nil)]
    }

    static func resuming(_ pauses: [PauseInterval], at date: Date) -> [PauseInterval] {
        guard isPaused(pauses), let last = pauses.indices.last else {
            return pauses
        }
        var updated = pauses
        updated[last].end = max(date, updated[last].start)
        return updated
    }
}
