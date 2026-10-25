import SwiftUI

struct HealthExportCard: View {
    let status: HealthExportStatus
    let canExport: Bool
    let exportTitle: String
    let isExporting: Bool
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Apple Health")
                .eyebrow()
            Label(status.title, systemImage: status == .exported ? "checkmark.circle.fill" : "heart")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(status == .exported ? AppColors.accent : AppColors.textPrimary)
            Text("Apple Health gets the workout type and active time. Sets and reps stay in Workout Pal.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
            if canExport {
                Button(action: onExport) {
                    if isExporting {
                        ProgressView()
                    } else {
                        Label(exportTitle, systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.secondaryAction)
                .disabled(isExporting)
            }
        }
        .card()
    }
}

#Preview {
    VStack {
        HealthExportCard(status: .notExported, canExport: true, exportTitle: "Save to Apple Health", isExporting: false) {}
        HealthExportCard(status: .exported, canExport: false, exportTitle: "", isExporting: false) {}
    }
    .padding()
    .background(AppColors.surface)
}
