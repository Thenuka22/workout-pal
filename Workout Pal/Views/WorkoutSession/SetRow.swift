import SwiftUI

struct SetRow: View {
    let index: Int
    let set: WorkoutSet
    let units: UnitPreference
    var focusedSet: FocusState<UUID?>.Binding
    let onReps: (Int) -> Void
    let onLoad: (Load) -> Void
    let onBodyweight: (Bool) -> Void
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Set \(index + 1)")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundStyle(set.isCompleted ? AppColors.accent : AppColors.textSecondary)
                if set.source == .camera {
                    Image(systemName: "camera.viewfinder")
                        .font(.caption)
                        .foregroundStyle(AppColors.accent)
                        .accessibilityLabel("Counted with the camera")
                }
                Spacer()
                if set.isCompleted {
                    Text("\(set.reps) reps · \(Formatting.load(set.load, units: units))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                }
                Button(action: onToggle) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(set.isCompleted ? AppColors.accent : AppColors.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(set.isCompleted ? "Mark set as not done" : "Mark set as done")
            }
            if !set.isCompleted {
                HStack(spacing: AppSpacing.medium) {
                    repsControl
                    Spacer(minLength: 0)
                    loadControl
                }
            }
        }
        .padding(AppSpacing.small + AppSpacing.xSmall)
        .background(
            set.isCompleted ? AppColors.accentSoft : AppColors.surfaceElevated,
            in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .strokeBorder(set.isCompleted ? AppColors.accent.opacity(0.4) : AppColors.outline, lineWidth: 1)
        }
        .contextMenu {
            Button("Remove set", role: .destructive, action: onRemove)
        }
    }

    private var repsControl: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Text("\(set.reps)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 28, alignment: .trailing)
            Text("reps")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            Stepper("Reps", value: repsBinding, in: 0...200)
                .labelsHidden()
        }
    }

    private var loadControl: some View {
        HStack(spacing: AppSpacing.small) {
            if !set.load.isBodyweight {
                TextField("0", value: loadBinding, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .focused(focusedSet, equals: set.id)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, AppSpacing.small)
                    .frame(width: 64, height: 32)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                Text(units.symbol)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Toggle("BW", isOn: bodyweightBinding)
                .toggleStyle(.button)
                .tint(AppColors.accent)
                .accessibilityLabel("Bodyweight")
        }
    }

    private var repsBinding: Binding<Int> {
        Binding(get: { set.reps }, set: { onReps($0) })
    }

    private var bodyweightBinding: Binding<Bool> {
        Binding(
            get: { set.load.isBodyweight },
            set: { onBodyweight($0) }
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
