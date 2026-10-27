import SwiftUI
import UIKit

struct LockWindowModifier: ViewModifier {
    let model: RootViewModel
    @State private var presenter = LockWindowPresenter()

    func body(content: Content) -> some View {
        content
            .onChange(of: model.showsLock, initial: true) { _, showsLock in
                if showsLock {
                    presenter.show(LockScreen(model: model), style: model.appearance.interfaceStyle)
                } else {
                    presenter.hide()
                }
            }
    }
}

private struct LockScreen: View {
    let model: RootViewModel

    var body: some View {
        LockView(
            unlockTitle: model.unlockTitle,
            symbolName: model.unlockSymbolName,
            message: model.unlockMessage,
            isUnlocking: model.isUnlocking,
            onUnlock: { model.unlock() },
            onSignOut: { model.signOutFromLock() }
        )
    }
}

@MainActor
private final class LockWindowPresenter {
    private var window: UIWindow?

    func show(_ content: some View, style: UIUserInterfaceStyle) {
        guard window == nil, let scene = Self.scene() else {
            return
        }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: content)
        window.makeKeyAndVisible()
        self.window = window
    }

    func hide() {
        guard let window else {
            return
        }
        let scene = window.windowScene
        window.isHidden = true
        self.window = nil
        scene?.windows.first { $0.windowLevel == .normal && !$0.isHidden }?.makeKey()
    }

    private static func scene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

extension View {
    func lockWindow(_ model: RootViewModel) -> some View {
        modifier(LockWindowModifier(model: model))
    }
}
