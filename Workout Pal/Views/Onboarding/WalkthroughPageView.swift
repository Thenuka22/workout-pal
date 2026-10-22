import SwiftUI

struct WalkthroughPageView: View {
    let page: WalkthroughPage
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Spacer(minLength: 0)
            illustration
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("0\(page.id + 1) / 0\(pageCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppColors.accent)
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.bottom, AppSpacing.medium)
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.accentSoft)
                .frame(width: 220, height: 220)
            Circle()
                .strokeBorder(AppColors.accent, lineWidth: 2)
                .frame(width: 180, height: 180)
            Circle()
                .fill(AppColors.surfaceElevated)
                .frame(width: 140, height: 140)
            Image(systemName: page.symbolName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(AppColors.accent)
        }
        .accessibilityHidden(true)
    }
}

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(0..<max(count, 1), id: \.self) { index in
                Capsule()
                    .fill(index == current ? AppColors.accent : AppColors.outline)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        WalkthroughPageView(
            page: WalkthroughPage(
                id: 0,
                symbolName: "figure.strengthtraining.traditional",
                title: "Start your journey toward a more active life.",
                subtitle: "Build a routine that fits your goals, your time and your everyday life."
            ),
            pageCount: 3
        )
        PageDots(count: 3, current: 0)
    }
    .background(AppColors.surface)
}
