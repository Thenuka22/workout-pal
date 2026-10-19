import SwiftUI

struct WorkoutHistoryView: View {
    let groups: [HistoryGroup]
    let units: UnitPreference
    let selectedSession: Binding<WorkoutSession?>?

    var body: some View {
        List {
            ForEach(groups) { group in
                Section("Week of \(Formatting.date(group.weekStart))") {
                    ForEach(group.sessions) { session in
                        if let selectedSession {
                            Button {
                                selectedSession.wrappedValue = session
                            } label: {
                                SessionRow(session: session, units: units)
                            }
                            .listRowBackground(
                                session.id == selectedSession.wrappedValue?.id ? AppColors.accent.opacity(0.2) : nil
                            )
                        } else {
                            NavigationLink(value: session) {
                                SessionRow(session: session, units: units)
                            }
                        }
                    }
                }
            }
        }
        .screenBackground()
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    let units: UnitPreference

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(session.routineName)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
            Text(Formatting.dateTime(session.startedAt))
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    private var detail: String {
        var parts = [
            Formatting.minutes(fromSeconds: session.activeSeconds),
            "\(session.completedSetCount) sets",
        ]
        if session.loadedVolumeKilograms > 0 {
            parts.append("\(Formatting.volume(kilograms: session.loadedVolumeKilograms, units: units)) lifted")
        }
        return parts.joined(separator: " · ")
    }
}
