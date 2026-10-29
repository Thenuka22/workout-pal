import SwiftUI

struct PersonalRecordsView: View {
    let records: [PersonalRecord]
    let units: UnitPreference

    var body: some View {
        List {
            ForEach(records.sorted { ($0.exerciseName, $0.kind.title) < ($1.exerciseName, $1.kind.title) }) { record in
                NavigationLink(value: ExerciseOption(id: record.exerciseID, name: record.exerciseName)) {
                    PersonalRecordRow(record: record, units: units)
                }
                .cardRow()
            }
        }
        .listStyle(.plain)
        .screenBackground()
        .navigationTitle("Personal records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    let units: UnitPreference

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(AppColors.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exerciseName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(record.kind.title) · \(Formatting.date(record.date))")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Text(Formatting.record(record, units: units))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}
