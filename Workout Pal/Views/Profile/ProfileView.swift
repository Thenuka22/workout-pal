import SwiftUI

struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @State private var model: ProfileViewModel
    @State private var isEditingHeight = false
    @State private var isConfirmingSignOut = false
    @State private var isConfirmingDelete = false

    init(model: ProfileViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                ScreenHeader(title: "Profile")
                VStack(spacing: AppSpacing.medium) {
                    profileCard
                    goalCard
                    section("Connected services") {
                        ForEach(model.connectedServices) { service in
                            NavigationLink(value: service.route) {
                                LinkRow(
                                    title: service.title,
                                    subtitle: service.subtitle,
                                    symbolName: service.symbolName,
                                    value: service.value,
                                    isHighlighted: service.isActive
                                )
                                .card()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    planCard
                    preferencesCard
                    section("Security & privacy") {
                        securityCard
                        privacyCard
                    }
                    accountCard
                    aboutCard
                }
                .padding(.horizontal, AppSpacing.medium)
            }
            .padding(.bottom, AppSpacing.large)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditingHeight) {
            heightSheet
        }
        .confirmationDialog(model.signOutTitle, isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button(model.signOutTitle, role: .destructive) {
                model.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your workouts stay on this device and come back when you sign in again.")
        }
        .confirmationDialog("Delete your workout data?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete workout data", role: .destructive) {
                model.deleteWorkoutData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes the routines, workouts, walks and runs saved for this account on this device and resets your preferences. Copies saved to Apple Health stay in the Health app.")
        }
        .alert("Something went wrong", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            await model.load()
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .permissions:
                PermissionsView(model: container.makePermissionsViewModel())
            case .health:
                HealthSettingsView(model: container.makeHealthSettingsViewModel())
            case .reminders:
                RemindersView(model: container.makeRemindersViewModel())
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: AppSpacing.medium) {
            AvatarBadge(initial: model.initial, size: 56)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                TextField("Your name", text: $model.displayName)
                    .textContentType(.name)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text(model.profileSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .card()
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Weekly workout goal")
                .eyebrow()
            HStack {
                Text("\(model.weeklyGoal) sessions")
                    .cardTitle()
                Spacer()
                Stepper("Weekly workout goal", value: $model.weeklyGoal, in: 1...14)
                    .labelsHidden()
            }
        }
        .card()
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Your plan")
                    .eyebrow()
                Text(model.planSummary)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Fitness level")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppSpacing.small) {
                    ForEach(FitnessLevel.allCases) { level in
                        Chip(title: level.title, isSelected: level == model.fitnessLevel) {
                            model.select(level)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Gender")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppSpacing.small) {
                    ForEach(GenderPreference.allCases) { gender in
                        Chip(title: gender.title, isSelected: gender == model.gender) {
                            model.select(gender)
                        }
                    }
                }
            }
            HStack {
                Text("Height")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button(model.heightText) {
                    isEditingHeight = true
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .card()
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Preferences")
                .eyebrow()
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Load units")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppSpacing.small) {
                    ForEach(UnitPreference.allCases) { units in
                        Chip(title: units.title, isSelected: units == model.units) {
                            model.units = units
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Appearance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppSpacing.small) {
                    ForEach(AppearancePreference.allCases) { appearance in
                        Chip(title: appearance.title, isSelected: appearance == model.appearance) {
                            model.appearance = appearance
                        }
                    }
                }
            }
            Toggle(isOn: $model.hapticsEnabled) {
                Text("Haptics")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accent)
            Toggle(isOn: $model.spokenRepCount) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Say reps out loud")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("While the camera counts squats and jumping jacks")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .tint(AppColors.accent)
        }
        .card()
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .cardTitle()
                .padding(.top, AppSpacing.small)
            content()
        }
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Toggle(isOn: Binding(get: { model.requiresUnlock }, set: { model.setRequiresUnlock($0) })) {
                Label(model.secureUnlockTitle, systemImage: model.unlockKind.symbolName)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accent)
            .disabled(model.unlockKind == .unavailable || model.isAuthenticating)
            Text(model.secureUnlockDetail)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var privacyCard: some View {
        NavigationLink(value: ProfileRoute.permissions) {
            LinkRow(
                title: "Privacy & permissions",
                subtitle: "Camera, motion, Apple Health and notifications",
                symbolName: "hand.raised.fill"
            )
            .card()
        }
        .buttonStyle(.plain)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Account")
                .eyebrow()
            Text(model.accountSummary)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
            Button(model.signOutTitle, role: .destructive) {
                isConfirmingSignOut = true
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            Divider()
                .overlay(AppColors.outline)
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                if model.isDeletingData {
                    ProgressView()
                } else {
                    Text("Delete my workout data")
                }
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .disabled(model.isDeletingData)
            Text("Your Google account is only used to sign in. Workouts are stored on this device.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("About")
                .eyebrow()
            HStack {
                Text("Workout Pal")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(model.appVersion)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(model.attributionText)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
            if let url = model.attributionURL {
                Link("Visit wger.de", destination: url)
                    .font(.footnote.weight(.semibold))
            }
        }
        .card()
    }

    private var heightSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xSmall) {
                    Text("\(model.heightCentimetres)")
                        .metric(size: 56)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("cm")
                        .font(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Picker("Height", selection: $model.heightCentimetres) {
                    ForEach(model.heightRange, id: \.self) { value in
                        Text("\(value) cm").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                Spacer()
            }
            .padding(AppSpacing.medium)
            .screenBackground()
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isEditingHeight = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return NavigationStack {
        ProfileView(model: container.makeProfileViewModel())
    }
    .environment(container)
}
