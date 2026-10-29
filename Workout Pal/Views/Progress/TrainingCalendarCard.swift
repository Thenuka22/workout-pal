import Foundation
import SwiftUI

struct TrainingCalendarCard: View {
    let model: ProgressHomeViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xSmall), count: 7)

    var body: some View {
        let month = model.trainingMonth
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Button {
                    model.showPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous month")
                Spacer()
                VStack(spacing: 2) {
                    Text(model.monthTitle)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(model.monthSummary)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                Button {
                    model.showNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .disabled(!model.canShowNextMonth)
                .accessibilityLabel("Next month")
            }
            LazyVGrid(columns: columns, spacing: AppSpacing.xSmall) {
                ForEach(Array(model.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .accessibilityHidden(true)
                }
                ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                    Color.clear
                        .frame(height: 36)
                        .accessibilityHidden(true)
                }
                ForEach(month.days) { day in
                    dayCell(day)
                }
            }
            HStack(spacing: AppSpacing.medium) {
                legend("Workout") {
                    Circle().fill(AppColors.accent)
                }
                legend("Walk or run") {
                    Circle().strokeBorder(AppColors.accent, lineWidth: 2)
                }
            }
            .accessibilityHidden(true)
            if let title = model.selectedDayTitle {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Button("Show all") {
                        model.clearSelectedDay()
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                }
            }
        }
        .card()
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = model.selectedDay == day.date
        return Button {
            model.select(day)
        } label: {
            Text(day.date.formatted(.dateTime.day()))
                .font(.subheadline.weight(day.hasTraining ? .bold : .regular).monospacedDigit())
                .foregroundStyle(day.workouts > 0 ? AppColors.onAccent : AppColors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background {
                    if day.workouts > 0 {
                        Circle().fill(AppColors.accent)
                    } else if day.activities > 0 {
                        Circle().strokeBorder(AppColors.accent, lineWidth: 2)
                    }
                }
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(AppColors.textPrimary, lineWidth: 2)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.accessibilityLabel(for: day))
        .accessibilityHint(day.hasTraining ? "Shows this day's sessions" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func legend<Mark: View>(_ title: String, @ViewBuilder mark: () -> Mark) -> some View {
        HStack(spacing: AppSpacing.xSmall) {
            mark()
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
