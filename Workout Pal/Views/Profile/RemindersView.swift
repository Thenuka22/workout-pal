import Foundation
import SwiftUI
import UIKit

struct RemindersView: View {
    @Environment(\.openURL) private var openURL
    @State private var model: RemindersViewModel

    init(model: RemindersViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                if model.isBlocked {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Label("Notifications are turned off for Workout Pal.", systemImage: "bell.slash.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.warning)
                        Button("Open Settings", action: openSettings)
                            .buttonStyle(.secondaryAction)
                    }
                    .card()
                }
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Toggle(isOn: Binding(get: { model.remindersEnabled }, set: { model.setRemindersEnabled($0) })) {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Workout reminders")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(model.summary)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .tint(AppColors.accent)
                    if model.remindersEnabled {
                        Text("Days")
                            .eyebrow()
                        HStack(spacing: AppSpacing.xSmall) {
                            ForEach(model.weekdayOptions) { option in
                                Button {
                                    model.toggle(option)
                                } label: {
                                    Text(option.title)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(model.isSelected(option) ? AppColors.onAccent : AppColors.textPrimary)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            model.isSelected(option) ? AppColors.accent : AppColors.surface,
                                            in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(model.isSelected(option) ? .isSelected : [])
                            }
                        }
                        DatePicker("Time", selection: $model.reminderTime, displayedComponents: .hourAndMinute)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .card()
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Toggle(isOn: Binding(get: { model.restAlertsEnabled }, set: { model.setRestAlertsEnabled($0) })) {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Rest timer alerts")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("Get a nudge when your rest is over, even if Workout Pal is in the background.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .tint(AppColors.accent)
                }
                .card()
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .task {
            await model.load()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
