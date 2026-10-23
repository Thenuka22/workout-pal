import SwiftUI

struct LinkRow: View {
    let title: String
    var subtitle: String? = nil
    let symbolName: String
    var value: String? = nil
    var isHighlighted = false

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(isHighlighted ? AppColors.onAccent : AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(isHighlighted ? AppColors.accent : AppColors.outline, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let value {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isHighlighted ? AppColors.accent : AppColors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: AppSpacing.medium) {
        LinkRow(title: "Apple Health", subtitle: "Read and save workout activity", symbolName: "heart.fill", value: "Connected", isHighlighted: true)
        LinkRow(title: "Privacy & permissions", symbolName: "hand.raised.fill")
    }
    .padding()
    .background(AppColors.surface)
}
