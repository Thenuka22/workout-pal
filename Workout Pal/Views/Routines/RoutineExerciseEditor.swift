import SwiftUI

struct RoutineExerciseEditor: View {
    @Binding var item: RoutineExercise
    let units: UnitPreference

    var body: some View {
        Form {
            Section("Plan") {
                Stepper("Sets: \(item.plannedSets)", value: $item.plannedSets, in: 1...10)
                Stepper("Reps: \(item.plannedReps)", value: $item.plannedReps, in: 1...100)
                Stepper("Rest: \(item.restSeconds) s", value: $item.restSeconds, in: 0...300, step: 15)
            }
            Section("Load") {
                Toggle("Bodyweight", isOn: bodyweightBinding)
                if !item.plannedLoad.isBodyweight {
                    HStack {
                        TextField("Load", value: loadBinding, format: .number.precision(.fractionLength(0...1)))
                            .keyboardType(.decimalPad)
                        Text(units.symbol)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .screenBackground()
        .navigationTitle(item.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bodyweightBinding: Binding<Bool> {
        Binding(
            get: { item.plannedLoad.isBodyweight },
            set: { isBodyweight in
                item.plannedLoad = isBodyweight ? .bodyweight : .kilograms(20)
            }
        )
    }

    private var loadBinding: Binding<Double> {
        Binding(
            get: { Formatting.displayValue(kilograms: item.plannedLoad.kilograms ?? 0, units: units) },
            set: { value in
                item.plannedLoad = .kilograms(max(0, Formatting.kilograms(fromDisplayValue: value, units: units)))
            }
        )
    }
}
