import SwiftUI

struct SearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .foregroundStyle(AppColors.textPrimary)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .frame(minHeight: 44)
        .background(AppColors.surfaceElevated, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(AppColors.outline, lineWidth: 1)
        }
    }
}

#Preview {
    SearchField(text: .constant("Push"), prompt: "Search exercises or routines")
        .padding()
        .background(AppColors.surface)
}
