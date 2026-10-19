import Foundation
import SwiftUI

struct RestTimerBar: View {
    let endsAt: Date
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "timer")
                .foregroundStyle(AppColors.accent)
            Text("Rest")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(timerInterval: Date.now...max(endsAt, Date.now), countsDown: true)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Skip", action: onSkip)
                .font(.subheadline.weight(.semibold))
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surfaceElevated)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
