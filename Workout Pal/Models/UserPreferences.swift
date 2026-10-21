enum UnitPreference: String, CaseIterable, Identifiable, Sendable {
    case kilograms
    case pounds

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kilograms: "Kilograms"
        case .pounds: "Pounds"
        }
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

struct UserPreferences: Hashable, Sendable {
    var displayName: String
    var weeklyGoal: Int
    var units: UnitPreference
    var appearance: AppearancePreference

    static let standard = UserPreferences(displayName: "", weeklyGoal: 3, units: .kilograms, appearance: .dark)
}
