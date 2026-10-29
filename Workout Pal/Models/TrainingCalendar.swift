import Foundation

struct CalendarDay: Identifiable, Hashable, Sendable {
    let date: Date
    let workouts: Int
    let activities: Int

    var id: Date { date }

    var hasTraining: Bool {
        workouts + activities > 0
    }
}

struct TrainingMonth: Hashable, Sendable {
    let start: Date
    /// Empty cells before the 1st so it lines up under the right weekday.
    let leadingBlanks: Int
    let days: [CalendarDay]

    var trainingDays: Int {
        days.filter(\.hasTraining).count
    }
}

enum TrainingCalendar {
    static func month(
        containing date: Date,
        sessions: [WorkoutSession],
        activities: [ActivitySession],
        calendar: Calendar = .current
    ) -> TrainingMonth {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count
        else {
            return TrainingMonth(start: date, leadingBlanks: 0, days: [])
        }
        let isInMonth = { (day: Date) in day >= interval.start && day < interval.end }
        var workouts: [Date: Int] = [:]
        for session in sessions where session.status == .completed && isInMonth(session.startedAt) {
            workouts[calendar.startOfDay(for: session.startedAt), default: 0] += 1
        }
        var walks: [Date: Int] = [:]
        for activity in activities where activity.status == .completed && isInMonth(activity.startedAt) {
            walks[calendar.startOfDay(for: activity.startedAt), default: 0] += 1
        }
        let days = (0..<dayCount).compactMap { offset -> CalendarDay? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: interval.start) else {
                return nil
            }
            let start = calendar.startOfDay(for: day)
            return CalendarDay(date: start, workouts: workouts[start] ?? 0, activities: walks[start] ?? 0)
        }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return TrainingMonth(start: interval.start, leadingBlanks: leading, days: days)
    }

    static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
