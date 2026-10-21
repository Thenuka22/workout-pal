import Foundation
import SwiftUI

struct WeekdayStrip: View {
    let trainedWeekdays: Set<Int>
    var calendar: Calendar = .current

    private var weekdays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(weekdays, id: \.self) { weekday in
                let trained = trainedWeekdays.contains(weekday)
                VStack(spacing: AppSpacing.xSmall) {
                    ZStack {
                        Circle()
                            .fill(trained ? AppColors.accent : AppColors.surfaceElevated)
                        Circle()
                            .strokeBorder(trained ? Color.clear : AppColors.outline, lineWidth: 1)
                        Text(symbol(for: weekday))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(trained ? AppColors.onAccent : AppColors.textSecondary)
                    }
                    .frame(width: 36, height: 36)
                    Image(systemName: trained ? "checkmark" : "minus")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(trained ? AppColors.accent : AppColors.outline)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trainedWeekdays.count) training days this week")
    }

    private func symbol(for weekday: Int) -> String {
        let symbols = calendar.veryShortWeekdaySymbols
        let index = weekday - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }
}

#Preview {
    WeekdayStrip(trainedWeekdays: [2, 3, 4])
        .padding()
        .background(AppColors.surface)
}
