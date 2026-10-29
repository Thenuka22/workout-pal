import Foundation
import Testing
@testable import Workout_Pal

struct FormattingTests {
    @Test func poundsRoundTripToKilograms() {
        let pounds = Formatting.displayValue(kilograms: 100, units: .pounds)
        #expect(abs(pounds - 220.462) < 0.001)
        #expect(abs(Formatting.kilograms(fromDisplayValue: pounds, units: .pounds) - 100) < 0.0001)
    }

    @Test func kilogramsAreShownAsStored() {
        #expect(Formatting.displayValue(kilograms: 42.5, units: .kilograms) == 42.5)
        #expect(Formatting.kilograms(fromDisplayValue: 42.5, units: .kilograms) == 42.5)
    }

    @Test func bodyweightIsNamedExplicitly() {
        #expect(Formatting.load(.bodyweight, units: .kilograms) == "Bodyweight")
        #expect(Formatting.volume(kilograms: 0, units: .pounds) == "Bodyweight only")
    }

    @Test func elapsedTimeUsesClockStyle() {
        #expect(Formatting.elapsed(seconds: 0) == "00:00")
        #expect(Formatting.elapsed(seconds: 75.9) == "01:15")
        #expect(Formatting.elapsed(seconds: 3_725) == "1:02:05")
        #expect(Formatting.elapsed(seconds: -5) == "00:00")
    }

    @Test func countsUseTheRightPlural() {
        #expect(Formatting.count(1, "set") == "1 set")
        #expect(Formatting.count(0, "set") == "0 sets")
        #expect(Formatting.count(3, "exercise") == "3 exercises")
        #expect(Formatting.count(2, "person", plural: "people") == "2 people")
    }

    @Test func setsAreSummarised() {
        let same = [SampleData.set(reps: 8, load: .kilograms(60)), SampleData.set(reps: 8, load: .kilograms(60))]
        #expect(Formatting.sets(same, units: .kilograms) == "2 × 8 · 60 kg")
        let mixed = [SampleData.set(reps: 8, load: .bodyweight), SampleData.set(reps: 6, load: .bodyweight)]
        #expect(Formatting.sets(mixed, units: .kilograms) == "8, 6 reps · Bodyweight")
    }

    @Test func unitSymbols() {
        #expect(UnitPreference.kilograms.symbol == "kg")
        #expect(UnitPreference.pounds.symbol == "lb")
    }
}
