import SwiftUI

struct WorkoutHistoryView<Header: View>: View {
    let groups: [HistoryGroup]
    let units: UnitPreference
    let selectedEntry: Binding<HistoryEntry?>?
    private let header: Header

    init(
        groups: [HistoryGroup],
        units: UnitPreference,
        selectedEntry: Binding<HistoryEntry?>?,
        @ViewBuilder header: () -> Header
    ) {
        self.groups = groups
        self.units = units
        self.selectedEntry = selectedEntry
        self.header = header()
    }

    var body: some View {
        List {
            header
                .plainRow(top: AppSpacing.medium)
            ForEach(groups) { group in
                Text("Week of \(Formatting.date(group.weekStart))")
                    .eyebrow()
                    .plainRow(top: AppSpacing.medium, bottom: AppSpacing.xSmall)
                ForEach(group.entries) { entry in
                    if let selectedEntry {
                        Button {
                            selectedEntry.wrappedValue = entry
                        } label: {
                            HistoryRow(entry: entry, units: units)
                        }
                        .cardRow(isSelected: entry.id == selectedEntry.wrappedValue?.id)
                    } else {
                        NavigationLink(value: entry) {
                            HistoryRow(entry: entry, units: units)
                        }
                        .cardRow()
                    }
                }
            }
        }
        .listStyle(.plain)
        .screenBackground()
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    let units: UnitPreference

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(AppColors.accent)
                .frame(width: 36, height: 36)
                .background(AppColors.accentSoft, in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(Formatting.dateTime(entry.startedAt))
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var symbolName: String {
        switch entry {
        case .workout: "dumbbell.fill"
        case .activity(let activity): activity.kind.symbolName
        }
    }

    private var detail: String {
        switch entry {
        case .workout(let session):
            var parts = [
                Formatting.minutes(fromSeconds: session.activeSeconds),
                Formatting.count(session.completedSetCount, "set"),
            ]
            if session.loadedVolumeKilograms > 0 {
                parts.append("\(Formatting.volume(kilograms: session.loadedVolumeKilograms, units: units)) lifted")
            }
            return parts.joined(separator: " · ")
        case .activity(let activity):
            var parts = [
                Formatting.minutes(fromSeconds: activity.activeSeconds),
                "\(Formatting.steps(activity.steps)) steps",
            ]
            if let meters = activity.distanceMeters {
                parts.append(Formatting.distance(meters: meters, units: units))
            }
            return parts.joined(separator: " · ")
        }
    }
}
