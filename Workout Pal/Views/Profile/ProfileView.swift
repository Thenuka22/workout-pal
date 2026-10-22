import SwiftUI

struct ProfileView: View {
    @State private var model: ProfileViewModel
    @State private var isEditingHeight = false

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
                    planCard
                    preferencesCard
                    aboutCard
                }
                .padding(.horizontal, AppSpacing.medium)
            }
            .padding(.bottom, AppSpacing.large)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditingHeight) {
            heightSheet
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
                Text("Your training profile")
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
                        .font(.system(size: 56, weight: .bold, design: .rounded))
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
    NavigationStack {
        ProfileView(model: AppContainer(inMemory: true).makeProfileViewModel())
    }
}
