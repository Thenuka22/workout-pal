import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColors.surfaceElevated,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.outline, lineWidth: 1)
            }
    }
}

struct CardRowModifier: ViewModifier {
    var isSelected = false

    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(
                top: AppSpacing.medium,
                leading: AppSpacing.large + AppSpacing.small,
                bottom: AppSpacing.medium,
                trailing: AppSpacing.large + AppSpacing.small
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(isSelected ? AppColors.accentSoft : AppColors.surfaceElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .strokeBorder(isSelected ? AppColors.accent : AppColors.outline, lineWidth: 1)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.xSmall)
            )
    }
}

struct PlainRowModifier: ViewModifier {
    var top: CGFloat = AppSpacing.small
    var bottom: CGFloat = AppSpacing.small
    var horizontal: CGFloat = AppSpacing.medium

    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: top, leading: horizontal, bottom: bottom, trailing: horizontal))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

extension View {
    func card() -> some View {
        modifier(CardModifier())
    }

    func cardRow(isSelected: Bool = false) -> some View {
        modifier(CardRowModifier(isSelected: isSelected))
    }

    func plainRow(
        top: CGFloat = AppSpacing.small,
        bottom: CGFloat = AppSpacing.small,
        horizontal: CGFloat = AppSpacing.medium
    ) -> some View {
        modifier(PlainRowModifier(top: top, bottom: bottom, horizontal: horizontal))
    }
}
