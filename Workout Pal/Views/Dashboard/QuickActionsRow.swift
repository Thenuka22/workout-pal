import SwiftUI

struct QuickActionsRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            NavigationLink(value: TrainRoute.activityTracker) {
                QuickActionLabel(title: "Walk & run", subtitle: "Track steps", symbolName: "figure.walk")
            }
            NavigationLink(value: TrainRoute.repCounter) {
                QuickActionLabel(title: "Count reps", subtitle: "With the camera", symbolName: "camera.viewfinder")
            }
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionLabel: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(AppColors.onAccent)
                .frame(width: 40, height: 40)
                .background(AppColors.accent, in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .card()
    }
}

#Preview {
    NavigationStack {
        QuickActionsRow()
            .padding()
            .background(AppColors.surface)
    }
}
