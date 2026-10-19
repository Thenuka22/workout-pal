import Foundation
import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession
    let units: UnitPreference

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Date", value: Formatting.dateTime(session.startedAt))
                LabeledContent("Duration", value: Formatting.minutes(fromSeconds: session.activeSeconds))
                LabeledContent("Sets done", value: "\(session.completedSetCount) of \(session.totalSetCount)")
                LabeledContent("Loaded volume", value: Formatting.volume(kilograms: session.loadedVolumeKilograms, units: units))
            }
            ForEach(session.exercises) { exercise in
                Section(exercise.exerciseName) {
                    if exercise.sets.isEmpty {
                        Text("No sets")
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Text("\(set.reps) reps · \(Formatting.load(set.load, units: units))")
                                    .foregroundStyle(AppColors.textSecondary)
                                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(set.isCompleted ? AppColors.success : AppColors.textSecondary)
                                    .accessibilityLabel(set.isCompleted ? "Done" : "Not done")
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }
        }
        .screenBackground()
        .navigationTitle(session.routineName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
