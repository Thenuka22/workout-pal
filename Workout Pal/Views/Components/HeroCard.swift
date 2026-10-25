import SwiftUI

struct HeroCard: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    let symbolName: String
    var actionSymbolName: String = "arrow.right"

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: symbolName)
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(AppColors.accent.opacity(0.12))
                .offset(x: 24, y: 24)
                .accessibilityHidden(true)
            HStack(alignment: .bottom, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(eyebrow)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .kerning(0.8)
                        .foregroundStyle(AppColors.onAccent)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.xSmall)
                        .background(AppColors.accent, in: Capsule())
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: actionSymbolName)
                    .font(.headline)
                    .foregroundStyle(AppColors.onAccent)
                    .frame(width: 48, height: 48)
                    .background(AppColors.accent, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppColors.accentSoft, AppColors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: shape
        )
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(AppColors.outline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: AppSpacing.medium) {
        HeroCard(
            eyebrow: "Today's plan",
            title: "Upper body strength",
            subtitle: "5 exercises · about 32 min",
            symbolName: "dumbbell.fill"
        )
        HeroCard(eyebrow: "Explore", title: "Exercise library", symbolName: "books.vertical.fill")
    }
    .padding()
    .background(AppColors.surface)
}
