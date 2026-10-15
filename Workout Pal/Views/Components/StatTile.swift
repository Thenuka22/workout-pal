import SwiftUI

struct StatTile: View {
    let title: String
    let value: String
    var caption: String? = nil
    var symbolName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xSmall) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .foregroundStyle(AppColors.accent)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}

#Preview {
    StatTile(title: "Workouts", value: "3", caption: "this week", symbolName: "flame.fill")
        .padding()
        .background(AppColors.surface)
}
