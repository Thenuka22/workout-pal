import Foundation

enum Formatting {
    static let poundsPerKilogram = 2.20462

    static func minutes(fromSeconds seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        return "\(minutes) min"
    }

    static func elapsed(seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let remainder = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%02d:%02d", minutes, remainder)
    }

    static func load(_ load: Load, units: UnitPreference) -> String {
        switch load {
        case .bodyweight:
            return "Bodyweight"
        case .kilograms(let kilograms):
            return "\(number(displayValue(kilograms: kilograms, units: units))) \(units.symbol)"
        }
    }

    static func volume(kilograms: Double, units: UnitPreference) -> String {
        guard kilograms > 0 else {
            return "Bodyweight only"
        }
        return "\(number(displayValue(kilograms: kilograms, units: units))) \(units.symbol)"
    }

    static func displayValue(kilograms: Double, units: UnitPreference) -> Double {
        switch units {
        case .kilograms: kilograms
        case .pounds: kilograms * poundsPerKilogram
        }
    }

    static func kilograms(fromDisplayValue value: Double, units: UnitPreference) -> Double {
        switch units {
        case .kilograms: value
        case .pounds: value / poundsPerKilogram
        }
    }

    static let metersPerMile = 1_609.344

    static func distance(meters: Double, units: UnitPreference) -> String {
        switch units {
        case .kilograms:
            return "\((meters / 1_000).formatted(.number.precision(.fractionLength(2)))) km"
        case .pounds:
            return "\((meters / metersPerMile).formatted(.number.precision(.fractionLength(2)))) mi"
        }
    }

    static func count(_ value: Int, _ singular: String, plural: String? = nil) -> String {
        "\(value) \(value == 1 ? singular : plural ?? singular + "s")"
    }

    static func steps(_ count: Int) -> String {
        count.formatted(.number)
    }

    static func record(_ record: PersonalRecord, units: UnitPreference) -> String {
        switch record.kind {
        case .heaviestLoad:
            "\(load(.kilograms(record.value), units: units)) × \(record.reps)"
        case .mostReps:
            count(record.reps, "rep")
        }
    }

    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    static func time(hour: Int, minute: Int, calendar: Calendar = .current) -> String {
        guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now) else {
            return String(format: "%02d:%02d", hour, minute)
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func weekdays(_ weekdays: Set<Int>, calendar: Calendar = .current) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday
        let ordered = (0..<7).map { ((first - 1 + $0) % 7) + 1 }.filter { weekdays.contains($0) }
        return ordered.map { symbols[$0 - 1] }.joined(separator: ", ")
    }

    static func reminder(_ preferences: UserPreferences, calendar: Calendar = .current) -> String {
        guard preferences.remindersEnabled, !preferences.reminderWeekdays.isEmpty else {
            return "Off"
        }
        let days = weekdays(preferences.reminderWeekdays, calendar: calendar)
        return "\(days) · \(time(hour: preferences.reminderHour, minute: preferences.reminderMinute, calendar: calendar))"
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

extension UnitPreference {
    var symbol: String {
        switch self {
        case .kilograms: "kg"
        case .pounds: "lb"
        }
    }
}
