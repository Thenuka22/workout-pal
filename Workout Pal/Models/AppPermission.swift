enum PermissionStatus: Sendable, Equatable {
    case notDetermined
    case granted
    case denied
    case restricted
    case unavailable
}

enum AppPermission: String, CaseIterable, Identifiable, Sendable {
    case camera
    case motion
    case health
    case notifications
    case deviceUnlock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: "Camera"
        case .motion: "Motion & Fitness"
        case .health: "Apple Health"
        case .notifications: "Notifications"
        case .deviceUnlock: "Face ID or passcode"
        }
    }

    var purpose: String {
        switch self {
        case .camera:
            "Counts squats and jumping jacks on this device. Frames are never saved or uploaded."
        case .motion:
            "Reads steps, distance and how you are moving during walks and runs."
        case .health:
            "Shows steps, distance and workouts from Apple Health, and saves the workouts you finish."
        case .notifications:
            "Sends workout reminders and tells you when your rest is over."
        case .deviceUnlock:
            "Locks Workout Pal when you leave it, if you turn on secure unlock."
        }
    }

    var symbolName: String {
        switch self {
        case .camera: "camera.fill"
        case .motion: "figure.walk.motion"
        case .health: "heart.fill"
        case .notifications: "bell.badge.fill"
        case .deviceUnlock: "faceid"
        }
    }

    func statusText(_ status: PermissionStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not asked yet"
        case .granted:
            switch self {
            case .health: return "Access requested"
            case .deviceUnlock: return "Ready"
            default: return "Allowed"
            }
        case .denied:
            return "Turned off"
        case .restricted:
            return "Restricted"
        case .unavailable:
            return self == .deviceUnlock ? "Set a passcode first" : "Not available on this device"
        }
    }
}
