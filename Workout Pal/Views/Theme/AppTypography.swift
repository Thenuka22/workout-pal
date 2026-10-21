import SwiftUI

struct EyebrowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .kerning(0.8)
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct ScreenTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct CardTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppColors.textPrimary)
    }
}

extension View {
    func eyebrow() -> some View {
        modifier(EyebrowModifier())
    }

    func screenTitle() -> some View {
        modifier(ScreenTitleModifier())
    }

    func cardTitle() -> some View {
        modifier(CardTitleModifier())
    }
}
