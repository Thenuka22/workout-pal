import SwiftUI

struct AvatarBadge: View {
    let initial: String
    var size: CGFloat = 44

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.onAccent)
            .frame(width: size, height: size)
            .background(AppColors.accent, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(AppColors.accentSoft, lineWidth: 2)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: AppSpacing.medium) {
        AvatarBadge(initial: "I")
        AvatarBadge(initial: "W", size: 64)
    }
    .padding()
    .background(AppColors.surface)
}
