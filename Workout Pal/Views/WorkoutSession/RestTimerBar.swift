import Foundation
import SwiftUI

struct RestTimerBar: View {
    let startedAt: Date
    let endsAt: Date
    var nextExerciseName: String? = nil
    let onSkip: () -> Void

    private var interval: ClosedRange<Date> {
        startedAt...max(endsAt, startedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Rest")
                    .eyebrow()
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.subheadline.weight(.semibold))
            }
            HStack(alignment: .firstTextBaseline) {
                Text(timerInterval: interval, countsDown: true)
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if let nextExerciseName {
                    Text("Next · \(nextExerciseName)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            ProgressView(timerInterval: interval, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(AppColors.accent)
        }
        .card()
    }
}

#Preview {
    RestTimerBar(startedAt: .now, endsAt: .now.addingTimeInterval(60), nextExerciseName: "Bent-over row") {}
        .padding()
        .background(AppColors.surface)
}
