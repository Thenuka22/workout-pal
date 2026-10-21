import SwiftUI

struct ScreenHeader<Trailing: View>: View {
    let title: String
    var overline: String? = nil
    var subtitle: String? = nil
    let trailing: Trailing

    init(
        title: String,
        overline: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.overline = overline
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                if let overline {
                    Text(overline)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(title)
                    .screenTitle()
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, overline: String? = nil, subtitle: String? = nil) {
        self.init(title: title, overline: overline, subtitle: subtitle) {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.large) {
        ScreenHeader(title: "Induwara", overline: "Good evening,", subtitle: "Here's how your week is shaping up.") {
            Circle()
                .fill(AppColors.accent)
                .frame(width: 44, height: 44)
        }
        ScreenHeader(title: "Your progress", subtitle: "Small steps are adding up.")
    }
    .background(AppColors.surface)
}
