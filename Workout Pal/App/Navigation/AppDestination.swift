enum AppDestination: String, CaseIterable, Identifiable {
    case home
    case train
    case progress
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .train: "Train"
        case .progress: "Progress"
        case .profile: "Profile"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "house.fill"
        case .train: "dumbbell.fill"
        case .progress: "chart.bar.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
