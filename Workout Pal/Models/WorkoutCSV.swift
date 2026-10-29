import Foundation

/// Spreadsheet-friendly copies of the history (RFC 4180 quoting, CRLF line endings).
enum WorkoutCSV {
    static func sets(sessions: [WorkoutSession], units: UnitPreference, timeZone: TimeZone = .current) -> String {
        var rows = [["Date", "Workout", "Exercise", "Set", "Reps", "Load", "Unit", "Bodyweight", "Source"]]
        let completed = sessions
            .filter { $0.status == .completed }
            .sorted { $0.startedAt < $1.startedAt }
        for session in completed {
            let date = timestamp(session.startedAt, timeZone: timeZone)
            for exercise in session.exercises {
                for (index, set) in exercise.sets.filter(\.isCompleted).enumerated() {
                    let load = set.load.kilograms.map { decimal(Formatting.displayValue(kilograms: $0, units: units)) }
                    rows.append([
                        date,
                        session.routineName,
                        exercise.exerciseName,
                        "\(index + 1)",
                        "\(set.reps)",
                        load ?? "",
                        load == nil ? "" : units.symbol,
                        set.load.isBodyweight ? "yes" : "no",
                        set.source.rawValue,
                    ])
                }
            }
        }
        return encode(rows)
    }

    static func activities(_ activities: [ActivitySession], units: UnitPreference, timeZone: TimeZone = .current) -> String {
        let distanceUnit = units == .pounds ? "mi" : "km"
        var rows = [["Date", "Type", "Minutes", "Steps", "Distance", "Unit"]]
        let completed = activities
            .filter { $0.status == .completed }
            .sorted { $0.startedAt < $1.startedAt }
        for activity in completed {
            let distance = activity.distanceMeters.map { meters in
                String(format: "%.2f", units == .pounds ? meters / Formatting.metersPerMile : meters / 1_000)
            }
            rows.append([
                timestamp(activity.startedAt, timeZone: timeZone),
                activity.kind.title,
                "\(Int((activity.activeSeconds / 60).rounded()))",
                "\(activity.steps)",
                distance ?? "",
                distance == nil ? "" : distanceUnit,
            ])
        }
        return encode(rows)
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func encode(_ rows: [[String]]) -> String {
        rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    /// Always uses a dot, whatever the device's number format, so spreadsheets read it as a number.
    private static func decimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private static func timestamp(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
