import SwiftUI

struct LockView: View {
    let unlockTitle: String
    let symbolName: String
    let message: String?
    let isUnlocking: Bool
    let onUnlock: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Spacer()
            Image(systemName: symbolName)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppColors.onAccent)
                .frame(width: 96, height: 96)
                .background(AppColors.accent, in: Circle())
                .accessibilityHidden(true)
            Text("Workout Pal is locked")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            Text("Your workout history is protected on this device.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            if let message {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppColors.warning)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button(action: onUnlock) {
                Label(unlockTitle, systemImage: symbolName)
            }
            .buttonStyle(.primaryAction)
            .disabled(isUnlocking)
            Button("Sign out instead", role: .destructive, action: onSignOut)
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface.ignoresSafeArea())
    }
}

#Preview {
    LockView(
        unlockTitle: "Unlock with Face ID",
        symbolName: "faceid",
        message: nil,
        isUnlocking: false,
        onUnlock: {},
        onSignOut: {}
    )
}
