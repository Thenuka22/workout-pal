import Foundation
import SwiftUI
import UIKit

struct PermissionsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: PermissionsViewModel

    init(model: PermissionsViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Workout Pal only asks for access when a feature needs it. You can change these at any time in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                VStack(spacing: AppSpacing.small) {
                    ForEach(model.rows) { row in
                        PermissionRowView(
                            row: row,
                            onAllow: { model.request(row.permission) },
                            onOpenSettings: openSettings
                        )
                    }
                }
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Your privacy")
                        .eyebrow()
                    ForEach(model.privacyNotes, id: \.self) { note in
                        Label(note, systemImage: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .card()
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Privacy & permissions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .task {
            await model.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refresh()
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

struct PermissionRowView: View {
    let row: PermissionRow
    let onAllow: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: row.permission.symbolName)
                .font(.headline)
                .foregroundStyle(row.status == .granted ? AppColors.onAccent : AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(row.status == .granted ? AppColors.accent : AppColors.outline, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.permission.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer(minLength: AppSpacing.small)
                    Text(row.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(row.status == .granted ? AppColors.accent : AppColors.textSecondary)
                }
                Text(row.permission.purpose)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if row.canRequest {
                    Button("Allow", action: onAllow)
                        .font(.subheadline.weight(.semibold))
                        .padding(.top, AppSpacing.xSmall)
                } else if row.needsSettings {
                    Button("Open Settings", action: onOpenSettings)
                        .font(.subheadline.weight(.semibold))
                        .padding(.top, AppSpacing.xSmall)
                }
            }
        }
        .card()
    }
}

#Preview {
    NavigationStack {
        PermissionsView(model: PermissionsViewModel(permissions: SystemPermissions()))
    }
}
