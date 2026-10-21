import SwiftUI

struct OptionCard: View {
    let title: String
    var subtitle: String? = nil
    var symbolName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? AppColors.onAccent : AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? AppColors.accent : AppColors.outline, in: Circle())
                }
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(isSelected ? AppColors.accent : Color.clear)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? Color.clear : AppColors.outline, lineWidth: 1.5)
                    }
                    .frame(width: 20, height: 20)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? AppColors.accentSoft : AppColors.surfaceElevated,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.accent : AppColors.outline, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: AppSpacing.small) {
        OptionCard(title: "Beginner", subtitle: "I'm just getting started", isSelected: false) {}
        OptionCard(title: "Intermediate", subtitle: "I work out some weeks", symbolName: "figure.run", isSelected: true) {}
    }
    .padding()
    .background(AppColors.surface)
}
