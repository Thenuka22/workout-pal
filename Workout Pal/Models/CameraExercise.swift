enum TrackingStatus: Equatable, Sendable {
    case searching
    case adjusting(String)
    case tracking

    var title: String {
        switch self {
        case .searching: "Looking for you"
        case .adjusting: "Adjust position"
        case .tracking: "Tracking"
        }
    }

    var message: String {
        switch self {
        case .searching: "Step into view so your whole body is on screen."
        case .adjusting(let hint): hint
        case .tracking: "You're in view. Keep your whole body on screen."
        }
    }

    var isTracking: Bool {
        self == .tracking
    }
}

enum CameraExercise: String, CaseIterable, Identifiable, Sendable {
    case squat
    case jumpingJack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .squat: "Squats"
        case .jumpingJack: "Jumping jacks"
        }
    }

    var symbolName: String {
        switch self {
        case .squat: "figure.strengthtraining.functional"
        case .jumpingJack: "figure.mixed.cardio"
        }
    }

    var exerciseID: Int {
        switch self {
        case .squat: -101
        case .jumpingJack: -102
        }
    }

    var summary: String {
        switch self {
        case .squat: "Counts each time you squat down and stand back up."
        case .jumpingJack: "Counts each jump out to a star and back together."
        }
    }

    var setupTips: [String] {
        switch self {
        case .squat:
            [
                "Prop your phone at hip height, about 2 to 3 metres away.",
                "Keep your hips, knees and feet in view. Side-on works best.",
                "Squat until your thighs are about level with the floor, then stand up tall.",
            ]
        case .jumpingJack:
            [
                "Prop your phone at chest height, about 2 to 3 metres away.",
                "Face the camera with your hands and feet in view.",
                "Jump your feet wide with hands overhead, then back together with hands by your sides.",
            ]
        }
    }

    func trackingStatus(for frame: PoseFrame?) -> TrackingStatus {
        guard let frame, frame.hasBody else {
            return .searching
        }
        switch self {
        case .squat:
            let leftLeg = frame.hasAll([.leftHip, .leftKnee, .leftAnkle])
            let rightLeg = frame.hasAll([.rightHip, .rightKnee, .rightAnkle])
            return leftLeg || rightLeg ? .tracking : .adjusting("Step back so your hips, knees and feet are in view.")
        case .jumpingJack:
            let arms = frame.hasAll([.leftShoulder, .rightShoulder, .leftWrist, .rightWrist])
            let legs = frame.hasAll([.leftHip, .rightHip, .leftAnkle, .rightAnkle])
            if !arms {
                return .adjusting("Step back so both hands are in view.")
            }
            return legs ? .tracking : .adjusting("Step back so both feet are in view.")
        }
    }

    static func matching(exerciseName: String) -> CameraExercise? {
        let name = exerciseName.lowercased()
        if name.contains("jumping jack") || name.contains("star jump") {
            return .jumpingJack
        }
        if name.contains("squat") {
            return .squat
        }
        return nil
    }
}
