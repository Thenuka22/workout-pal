import SwiftUI

struct SetRow: View {
    let index: Int
    let set: WorkoutSet
    let units: UnitPreference
    let onReps: (Int) -> Void
    let onLoad: (Load) -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Set \(index + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(set.isCompleted ? AppColors.success : AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(set.isCompleted ? "Mark set as not done" : "Mark set as done")
            }
            HStack(spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    Text("\(set.reps) reps")
                        .monospacedDigit()
                        .frame(minWidth: 64, alignment: .leading)
                    Stepper("Reps", value: repsBinding, in: 0...200)
                        .labelsHidden()
                }
                Spacer()
                if set.isCompleted {
                    Text(Formatting.load(set.load, units: units))
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    loadControl
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, AppSpacing.xSmall)
        .opacity(set.isCompleted ? 0.75 : 1)
    }

    @ViewBuilder
    private var loadControl: some View {
        HStack(spacing: AppSpacing.small) {
            if !set.load.isBodyweight {
                TextField("0", value: loadBinding, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                Text(units.symbol)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Toggle("BW", isOn: bodyweightBinding)
                .toggleStyle(.button)
                .accessibilityLabel("Bodyweight")
        }
    }

    private var repsBinding: Binding<Int> {
        Binding(get: { set.reps }, set: { onReps($0) })
    }

    private var bodyweightBinding: Binding<Bool> {
        Binding(
            get: { set.load.isBodyweight },
            set: { isBodyweight in
                onLoad(isBodyweight ? .bodyweight : .kilograms(20))
            }
        )
    }

    private var loadBinding: Binding<Double> {
        Binding(
            get: { Formatting.displayValue(kilograms: set.load.kilograms ?? 0, units: units) },
            set: { value in
                onLoad(.kilograms(max(0, Formatting.kilograms(fromDisplayValue: value, units: units))))
            }
        )
    }
}
