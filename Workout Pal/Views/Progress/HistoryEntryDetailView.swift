import SwiftUI

struct HistoryEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: HistoryDetailViewModel
    @State private var isConfirmingDelete = false
    private let isEmbedded: Bool
    private let onChange: () -> Void
    private let onDeleted: () -> Void

    init(
        model: HistoryDetailViewModel,
        isEmbedded: Bool = false,
        onChange: @escaping () -> Void = {},
        onDeleted: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)
        self.isEmbedded = isEmbedded
        self.onChange = onChange
        self.onDeleted = onDeleted
    }

    var body: some View {
        Group {
            switch model.entry {
            case .workout(let session):
                WorkoutDetailView(session: session, units: model.units) {
                    exportCard
                    shareButton
                    deleteButton
                }
            case .activity(let activity):
                ActivityDetailView(activity: activity, units: model.units) {
                    exportCard
                    shareButton
                    deleteButton
                }
            }
        }
        .confirmationDialog("Delete from your history?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.delete()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text(model.deleteMessage)
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: model.exportStatus) { _, _ in
            onChange()
        }
        .onChange(of: model.isDeleted) { _, isDeleted in
            if isDeleted {
                onDeleted()
                if !isEmbedded {
                    dismiss()
                }
            }
        }
    }

    private var shareButton: some View {
        ShareLink(item: model.shareText) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.secondaryAction)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isConfirmingDelete = true
        } label: {
            Label("Delete from history", systemImage: "trash")
        }
        .buttonStyle(.secondaryAction)
    }

    private var exportCard: some View {
        HealthExportCard(
            status: model.exportStatus,
            canExport: model.canExport,
            exportTitle: model.exportTitle,
            isExporting: model.isExporting
        ) {
            model.exportToHealth()
        }
    }
}
