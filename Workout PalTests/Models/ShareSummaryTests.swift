import Foundation
import Testing
@testable import Workout_Pal

struct ShareSummaryTests {
    private func lines(_ text: String) -> [String] {
        text.split(separator: "\n").map(String.init)
    }

    @Test func aWorkoutListsOnlyItsDoneSets() {
        let session = SampleData.session(minutes: 45, exercises: [
            SampleData.exercise(name: "Squats", sets: [
                SampleData.set(reps: 8, load: .kilograms(60)),
                SampleData.set(reps: 8, load: .kilograms(60)),
                SampleData.set(isCompleted: false),
            ]),
            SampleData.exercise(id: 2, name: "Plank", sets: [SampleData.set(isCompleted: false)]),
        ])
        let text = lines(ShareSummary.text(for: .workout(session), units: .kilograms))
        #expect(text[0].hasPrefix("Leg day · "))
        #expect(text[1] == "45 min · 2 sets · 960 kg lifted")
        #expect(text[2] == "Squats: 2 × 8 · 60 kg")
        #expect(!text.contains { $0.contains("Plank") })
        #expect(text.last == "Logged with Workout Pal")
    }

    @Test func loadsFollowTheUnitSetting() {
        let session = SampleData.session(exercises: [
            SampleData.exercise(sets: [SampleData.set(reps: 5, load: .kilograms(100))]),
        ])
        let text = lines(ShareSummary.text(for: .workout(session), units: .pounds))
        #expect(text[2].hasPrefix("Squats: 1 × 5 · 220"))
        #expect(text[2].hasSuffix(" lb"))
    }

    @Test func bodyweightWorkoutsLeaveOutVolume() {
        let session = SampleData.session(minutes: 20, exercises: [
            SampleData.exercise(name: "Push-ups", sets: [SampleData.set(reps: 12, load: .bodyweight)]),
        ])
        let text = lines(ShareSummary.text(for: .workout(session), units: .kilograms))
        #expect(text[1] == "20 min · 1 set")
        #expect(text[2] == "Push-ups: 1 × 12 · Bodyweight")
    }

    @Test func aWalkWithoutDistanceSaysNothingAboutIt() {
        let walk = SampleData.activity(minutes: 20, steps: 900, distanceMeters: nil)
        let text = lines(ShareSummary.text(for: .activity(walk), units: .kilograms))
        #expect(text[0].hasPrefix("Walk · "))
        #expect(text[1] == "20 min · 900 steps")
    }

    @Test func aRunsDistanceIsMarkedAsAnEstimate() {
        let run = SampleData.activity(kind: .run, minutes: 30, steps: 900, distanceMeters: 5_000)
        let text = ShareSummary.text(for: .activity(run), units: .kilograms)
        #expect(text.contains("km (estimated)"))
    }
}
