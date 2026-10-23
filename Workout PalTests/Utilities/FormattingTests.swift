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

    @Test func unitSymbols() {
        #expect(UnitPreference.kilograms.symbol == "kg")
        #expect(UnitPreference.pounds.symbol == "lb")
    }
}
