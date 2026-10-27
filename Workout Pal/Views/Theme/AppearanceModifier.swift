import SwiftUI
import UIKit

struct AppearanceModifier: ViewModifier {
    let preference: AppearancePreference

    func body(content: Content) -> some View {
        content
            .onChange(of: preference, initial: true) { _, preference in
                Self.apply(preference)
            }
    }

    private static func apply(_ preference: AppearancePreference) {
        let style = preference.interfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

extension AppearancePreference {
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

extension View {
    func appearance(_ preference: AppearancePreference) -> some View {
        modifier(AppearanceModifier(preference: preference))
    }
}
