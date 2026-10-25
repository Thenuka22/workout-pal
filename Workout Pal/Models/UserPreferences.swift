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

enum GenderPreference: String, CaseIterable, Identifiable, Sendable {
    case male
    case female
    case unspecified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .unspecified: "Prefer not to say"
        }
    }

    var symbolName: String {
        switch self {
        case .male: "figure.stand"
        case .female: "figure.stand.dress"
        case .unspecified: "person.fill.questionmark"
        }
    }
}

enum FitnessLevel: String, CaseIterable, Identifiable, Sendable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "I'm just getting started"
        case .intermediate: "I work out some weeks"
        case .advanced: "I train regularly"
        }
    }

    var suggestedWeeklyGoal: Int {
        switch self {
        case .beginner: 2
        case .intermediate: 3
        case .advanced: 5
        }
    }
}

struct UserPreferences: Hashable, Sendable {
    static let heightRange = 120...220

    var displayName: String
    var weeklyGoal: Int
    var units: UnitPreference
    var appearance: AppearancePreference
    var gender: GenderPreference?
    var heightCentimetres: Int?
    var fitnessLevel: FitnessLevel?
    var hasCompletedOnboarding: Bool
    var requiresUnlock = false
    var exportsToHealth = false

    static let standard = UserPreferences(
        displayName: "",
        weeklyGoal: 3,
        units: .kilograms,
        appearance: .dark,
        gender: nil,
        heightCentimetres: nil,
        fitnessLevel: nil,
        hasCompletedOnboarding: false
    )
}
