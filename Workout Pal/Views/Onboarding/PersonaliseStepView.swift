import SwiftUI

struct PersonaliseStepView<Content: View>: View {
    let stepNumber: Int
    let stepCount: Int
    let title: String
    let subtitle: String
    let footnote: String?
    let continueTitle: String
    let canContinue: Bool
    let canGoBack: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    let content: Content

    init(
        stepNumber: Int,
        stepCount: Int,
        title: String,
        subtitle: String,
        footnote: String? = nil,
        continueTitle: String,
        canContinue: Bool,
        canGoBack: Bool = true,
        onBack: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.stepNumber = stepNumber
        self.stepCount = stepCount
        self.title = title
        self.subtitle = subtitle
        self.footnote = footnote
        self.continueTitle = continueTitle
        self.canContinue = canContinue
        self.canGoBack = canGoBack
        self.onBack = onBack
        self.onContinue = onContinue
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Back")
                .opacity(canGoBack ? 1 : 0)
                .disabled(!canGoBack)
                Spacer()
                Text("Personalise your plan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(stepNumber) / \(stepCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
            }
            ProgressView(value: Double(stepNumber), total: Double(max(stepCount, 1)))
                .tint(AppColors.accent)
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AppSpacing.medium)
            content
                .padding(.top, AppSpacing.small)
            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
            Button(continueTitle, action: onContinue)
                .buttonStyle(.primaryAction)
                .disabled(!canContinue)
        }
        .padding(AppSpacing.medium)
    }
}

#Preview {
    PersonaliseStepView(
        stepNumber: 3,
        stepCount: 3,
        title: "What's your fitness level?",
        subtitle: "Choose the best fit right now.",
        footnote: "We'll suggest a weekly goal at this level.",
        continueTitle: "Build my plan",
        canContinue: true,
        onBack: {},
        onContinue: {}
    ) {
        OptionCard(title: "Intermediate", subtitle: "I work out some weeks", isSelected: true) {}
    }
    .background(AppColors.surface)
}
