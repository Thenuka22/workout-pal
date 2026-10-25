import AVFoundation
import Foundation
import UIKit

@MainActor
final class SpeechHapticsFeedback: WorkoutFeedback {
    private let settings: AppSettings
    private let synthesizer = AVSpeechSynthesizer()
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    init(settings: AppSettings) {
        self.settings = settings
        synthesizer.usesApplicationAudioSession = false
    }

    func repCounted(_ count: Int) {
        if settings.preferences.hapticsEnabled {
            impact.impactOccurred()
        }
        guard settings.preferences.spokenRepCount, !UIAccessibility.isVoiceOverRunning else {
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(AVSpeechUtterance(string: "\(count)"))
    }

    func setCompleted() {
        if settings.preferences.hapticsEnabled {
            notification.notificationOccurred(.success)
        }
    }

    func restFinished() {
        if settings.preferences.hapticsEnabled {
            notification.notificationOccurred(.warning)
        }
    }
}
