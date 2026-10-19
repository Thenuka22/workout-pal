import SwiftUI

struct ProfileView: View {
    @State private var model: ProfileViewModel

    init(model: ProfileViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display name", text: $model.displayName)
                    .textContentType(.name)
            }
            Section("Goals") {
                Stepper("Weekly workout goal: \(model.weeklyGoal)", value: $model.weeklyGoal, in: 1...14)
            }
            Section("Units") {
                Picker("Load units", selection: $model.units) {
                    ForEach(UnitPreference.allCases) { units in
                        Text(units.title).tag(units)
                    }
                }
            }
            Section("Appearance") {
                Picker("Appearance", selection: $model.appearance) {
                    ForEach(AppearancePreference.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("About") {
                LabeledContent("App", value: "Workout Pal")
                LabeledContent("Version", value: model.appVersion)
                Text(model.attributionText)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                if let url = model.attributionURL {
                    Link("Visit wger.de", destination: url)
                        .font(.footnote)
                }
            }
        }
        .screenBackground()
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        ProfileView(model: AppContainer(inMemory: true).makeProfileViewModel())
    }
}
