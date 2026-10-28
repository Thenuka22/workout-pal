import SwiftUI

struct RoutineExerciseEditor: View {
    @Binding var item: RoutineExercise
    let units: UnitPreference
    @State private var lastKilograms: Double = 20
    @FocusState private var isEditingLoad: Bool

    var body: some View {
        Form {
            Section {
                Stepper("Sets: \(item.plannedSets)", value: $item.plannedSets, in: 1...10)
                Stepper("Reps: \(item.plannedReps)", value: $item.plannedReps, in: 1...100)
                Stepper("Rest: \(item.restSeconds) s", value: $item.restSeconds, in: 0...300, step: 15)
            } header: {
                Text("Plan")
                    .eyebrow()
            }
            .listRowBackground(AppColors.surfaceElevated)
            Section {
                Toggle("Bodyweight", isOn: bodyweightBinding)
                    .tint(AppColors.accent)
                if !item.plannedLoad.isBodyweight {
                    HStack {
                        TextField("Load", value: loadBinding, format: .number.precision(.fractionLength(0...1)))
                            .keyboardType(.decimalPad)
                            .focused($isEditingLoad)
                        Text(units.symbol)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            } header: {
                Text("Load")
                    .eyebrow()
            }
            .listRowBackground(AppColors.surfaceElevated)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isEditingLoad = false
                }
                .fontWeight(.semibold)
            }
        }
        .navigationTitle(item.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
    }

    private var bodyweightBinding: Binding<Bool> {
        Binding(
            get: { item.plannedLoad.isBodyweight },
            set: { isBodyweight in
                if isBodyweight {
                    if let kilograms = item.plannedLoad.kilograms, kilograms > 0 {
                        lastKilograms = kilograms
                    }
                    item.plannedLoad = .bodyweight
                } else {
                    item.plannedLoad = .kilograms(lastKilograms)
                }
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
