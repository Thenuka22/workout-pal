import SwiftUI

struct StatTile: View {
    let title: String
    let value: String
    var caption: String? = nil
    var dotColor: Color = AppColors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}

#Preview {
    HStack(spacing: AppSpacing.small) {
        StatTile(title: "Workouts", value: "3 of 4", caption: "this week", dotColor: AppColors.infoOrange)
        StatTile(title: "Active time", value: "42 min", caption: "this week", dotColor: AppColors.infoBlue)
        StatTile(title: "Volume", value: "1,240 kg", caption: "lifted", dotColor: AppColors.infoPurple)
    }
    .padding()
    .background(AppColors.surface)
}
