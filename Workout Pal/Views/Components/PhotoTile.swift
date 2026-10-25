import SwiftUI

struct PhotoTile: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let imageName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(AppColors.onAccent)
                .frame(width: 36, height: 36)
                .background(AppColors.accent, in: Circle())
                .accessibilityHidden(true)
                .padding(.bottom, AppSpacing.xSmall)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2, reservesSpace: true)
        }
        .padding(AppSpacing.medium)
        .photoCard(imageName, minHeight: 170)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.outline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: AppSpacing.small) {
        PhotoTile(title: "Walk & run", subtitle: "Steps, distance and time", symbolName: "figure.walk", imageName: AppImages.dawnJogWide)
        PhotoTile(title: "Count reps", subtitle: "Squats and jumping jacks", symbolName: "camera.viewfinder", imageName: AppImages.controlledSquatWide)
    }
    .padding()
    .background(AppColors.surface)
}
