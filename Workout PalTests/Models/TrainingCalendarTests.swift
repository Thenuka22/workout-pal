import Foundation
import Testing
@testable import Workout_Pal

struct TrainingCalendarTests {
    @Test func theMonthLinesUpUnderItsFirstWeekday() {
        // 1 October 2026 is a Thursday.
        let month = TrainingCalendar.month(containing: SampleData.now, sessions: [], activities: [], calendar: SampleData.calendar)
        #expect(month.days.count == 31)
        #expect(month.leadingBlanks == 3)
        var sundayFirst = SampleData.calendar
        sundayFirst.firstWeekday = 1
        let shifted = TrainingCalendar.month(containing: SampleData.now, sessions: [], activities: [], calendar: sundayFirst)
        #expect(shifted.leadingBlanks == 4)
    }

    @Test func daysCountWorkoutsAndWalksInThatMonthOnly() {
        let sessions = [
            SampleData.session(startedAt: SampleData.date(year: 2026, month: 10, day: 21, hour: 7)),
            SampleData.session(startedAt: SampleData.date(year: 2026, month: 10, day: 5)),
            SampleData.session(startedAt: SampleData.date(year: 2026, month: 9, day: 30)),
            SampleData.session(startedAt: SampleData.date(year: 2026, month: 10, day: 12), status: .active),
        ]
        let activities = [SampleData.activity(startedAt: SampleData.date(year: 2026, month: 10, day: 21, hour: 18))]
        let month = TrainingCalendar.month(
            containing: SampleData.now,
            sessions: sessions,
            activities: activities,
            calendar: SampleData.calendar
        )
        #expect(month.days[20].workouts == 1)
        #expect(month.days[20].activities == 1)
        #expect(month.days[4].workouts == 1)
        #expect(month.days[11].hasTraining == false)
        #expect(month.trainingDays == 2)
    }

    @Test func weekdaySymbolsStartOnTheCalendarsFirstDay() {
        let symbols = TrainingCalendar.weekdaySymbols(calendar: SampleData.calendar)
        #expect(symbols.count == 7)
        #expect(symbols.first == SampleData.calendar.veryShortStandaloneWeekdaySymbols[1])
    }
}
