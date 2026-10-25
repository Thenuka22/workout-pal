import SwiftUI

struct HealthSettingsView: View {
    @State private var model: HealthSettingsViewModel

    init(model: HealthSettingsViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text(model.statusText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(model.isConnected ? AppColors.accent : AppColors.textSecondary)
                    }
                    if model.isAvailable && !model.isConnected {
                        Button("Connect Apple Health") {
                            model.connect()
                        }
                        .buttonStyle(.primaryAction)
                    }
                }
                .card()
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Toggle(isOn: Binding(get: { model.exportsToHealth }, set: { model.setExportsToHealth($0) })) {
                        Text("Save finished workouts")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .tint(AppColors.accent)
                    .disabled(!model.isAvailable)
                    Text("Workouts, walks and runs are saved to Apple Health when you finish them. You can also save one from its page in your history.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .card()
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Good to know")
                        .eyebrow()
                    ForEach(model.notes, id: \.self) { note in
                        Label(note, systemImage: "info.circle")
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
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .task {
            await model.load()
        }
    }
}
