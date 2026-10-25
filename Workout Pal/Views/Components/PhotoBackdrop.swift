import SwiftUI

struct PhotoBackdrop: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.1), .black.opacity(0.35), .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .accessibilityHidden(true)
    }
}

struct PhotoCardModifier: ViewModifier {
    let imageName: String
    var minHeight: CGFloat = 200

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .bottomLeading)
            .environment(\.colorScheme, .dark)
            .background {
                PhotoBackdrop(imageName: imageName)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

extension View {
    func photoCard(_ imageName: String, minHeight: CGFloat = 200) -> some View {
        modifier(PhotoCardModifier(imageName: imageName, minHeight: minHeight))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.small) {
        Text("Today's plan")
            .eyebrow()
        Text("Upper body strength")
            .font(.title2.weight(.bold))
            .foregroundStyle(AppColors.textPrimary)
    }
    .padding(AppSpacing.medium)
    .photoCard(AppImages.shoulderPressWide)
    .padding()
    .background(AppColors.surface)
}
