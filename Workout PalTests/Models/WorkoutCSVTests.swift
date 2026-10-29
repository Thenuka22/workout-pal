import Foundation
import Testing
@testable import Workout_Pal

struct WorkoutCSVTests {
    private let utc = TimeZone(secondsFromGMT: 0) ?? .current

    private func rows(_ csv: String) -> [String] {
        csv.components(separatedBy: "\r\n").filter { !$0.isEmpty }
    }

    @Test func eachDoneSetIsARow() {
        let session = SampleData.session(exercises: [
            SampleData.exercise(sets: [
                SampleData.set(reps: 8, load: .kilograms(60)),
                SampleData.set(reps: 12, load: .bodyweight, source: .camera),
                SampleData.set(isCompleted: false),
            ]),
        ])
        let lines = rows(WorkoutCSV.sets(sessions: [session], units: .kilograms, timeZone: utc))
        #expect(lines.count == 3)
        #expect(lines[0] == "Date,Workout,Exercise,Set,Reps,Load,Unit,Bodyweight,Source")
        #expect(lines[1] == "2026-10-21 12:00,Leg day,Squats,1,8,60,kg,no,manual")
        #expect(lines[2] == "2026-10-21 12:00,Leg day,Squats,2,12,,,yes,camera")
    }

    @Test func loadsUseTheChosenUnit() {
        let session = SampleData.session(exercises: [SampleData.exercise(sets: [SampleData.set(reps: 5, load: .kilograms(100))])])
        let lines = rows(WorkoutCSV.sets(sessions: [session], units: .pounds, timeZone: utc))
        #expect(lines[1].hasSuffix(",5,220.5,lb,no,manual"))
    }

    @Test func fieldsWithCommasAndQuotesAreQuoted() {
        #expect(WorkoutCSV.escape("Push, pull") == "\"Push, pull\"")
        #expect(WorkoutCSV.escape("The \"big\" day") == "\"The \"\"big\"\" day\"")
        #expect(WorkoutCSV.escape("Plain") == "Plain")
        #expect(WorkoutCSV.escape("Two\r\nlines") == "\"Two\r\nlines\"")
        let session = SampleData.session(name: "Push, pull")
        let lines = rows(WorkoutCSV.sets(sessions: [session], units: .kilograms, timeZone: utc))
        #expect(lines[1].contains(",\"Push, pull\",Squats,"))
    }

    @Test func walksListTheirDistanceWhenMeasured() {
        let walks = [
            SampleData.activity(minutes: 20, steps: 2_400, distanceMeters: 1_800),
            SampleData.activity(kind: .run, startedAt: SampleData.daysAgo(1), minutes: 30, steps: 4_000, distanceMeters: nil),
        ]
        let lines = rows(WorkoutCSV.activities(walks, units: .kilograms, timeZone: utc))
        #expect(lines[0] == "Date,Type,Minutes,Steps,Distance,Unit")
        #expect(lines[1] == "2026-10-20 12:00,Run,30,4000,,")
        #expect(lines[2] == "2026-10-21 12:00,Walk,20,2400,1.80,km")
    }
}
