import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: OnboardingViewModel

    init(model: OnboardingViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            switch model.step {
            case .profile:
                profileStep
            case .gender:
                genderStep
            case .height:
                heightStep
            case .fitnessLevel:
                fitnessLevelStep
            case .secureUnlock:
                secureUnlockStep
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.step)
    }

    private var profileStep: some View {
        PersonaliseStepView(
            stepNumber: model.personaliseStepNumber,
            stepCount: model.personaliseStepCount,
            title: "Let's start.",
            subtitle: "Create a profile to make your plan yours.",
            footnote: "Your name appears on your dashboard and profile. You can change it later.",
            continueTitle: "Continue",
            canContinue: model.canContinue,
            canGoBack: model.canGoBack,
            onBack: { model.back() },
            onContinue: { model.next() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                TextField("Your name", text: $model.displayName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .onSubmit {
                        model.next()
                    }
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.medium)
                    .frame(minHeight: 52)
                    .background(
                        AppColors.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                            .strokeBorder(AppColors.outline, lineWidth: 1)
                    }
            }
        }
    }

    private var genderStep: some View {
        PersonaliseStepView(
            stepNumber: model.personaliseStepNumber,
            stepCount: model.personaliseStepCount,
            title: "What's your gender?",
            subtitle: "It's saved to your profile only. You can change it later in Profile.",
            footnote: "Your gender is optional and private.",
            continueTitle: "Continue",
            canContinue: model.canContinue,
            canGoBack: model.canGoBack,
            onBack: { model.back() },
            onContinue: { model.next() }
        ) {
            VStack(spacing: AppSpacing.small) {
                ForEach(GenderPreference.allCases) { gender in
                    OptionCard(title: gender.title, symbolName: gender.symbolName, isSelected: gender == model.gender) {
                        model.select(gender)
                    }
                }
            }
        }
    }

    private var heightStep: some View {
        PersonaliseStepView(
            stepNumber: model.personaliseStepNumber,
            stepCount: model.personaliseStepCount,
            title: "What is your height?",
            subtitle: "It's saved to your profile. You can change it later in Profile.",
            continueTitle: "Continue",
            canContinue: model.canContinue,
            canGoBack: model.canGoBack,
            onBack: { model.back() },
            onContinue: { model.next() }
        ) {
            VStack(spacing: AppSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xSmall) {
                    Text("\(model.heightCentimetres)")
                        .metric(size: 64)
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
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var fitnessLevelStep: some View {
        PersonaliseStepView(
            stepNumber: model.personaliseStepNumber,
            stepCount: model.personaliseStepCount,
            title: "What's your fitness level?",
            subtitle: "Choose the best fit right now. You can adjust this as you build your routine.",
            footnote: "We'll suggest a weekly goal at this level.",
            continueTitle: model.offersSecureUnlock ? "Continue" : "Build my plan",
            canContinue: model.canContinue,
            canGoBack: model.canGoBack,
            onBack: { model.back() },
            onContinue: { model.next() }
        ) {
            VStack(spacing: AppSpacing.small) {
                ForEach(FitnessLevel.allCases) { level in
                    OptionCard(title: level.title, subtitle: level.subtitle, isSelected: level == model.fitnessLevel) {
                        model.select(level)
                    }
                }
            }
        }
    }

    private var secureUnlockStep: some View {
        PersonaliseStepView(
            stepNumber: model.personaliseStepNumber,
            stepCount: model.personaliseStepCount,
            title: "Keep your history private?",
            subtitle: "Lock Workout Pal with \(model.unlockKind.title) whenever you leave the app. You can change this later in Profile.",
            footnote: model.errorMessage,
            continueTitle: model.enableUnlockTitle,
            canContinue: model.canContinue,
            canGoBack: model.canGoBack,
            onBack: { model.back() },
            onContinue: { model.next() }
        ) {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: model.unlockKind.symbolName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(AppColors.onAccent)
                    .frame(width: 120, height: 120)
                    .background(AppColors.accent, in: Circle())
                    .accessibilityHidden(true)
                Button("Not now") {
                    model.skipSecureUnlock()
                }
                .buttonStyle(.secondaryAction)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    OnboardingView(model: AppContainer(inMemory: true).makeOnboardingViewModel())
}
