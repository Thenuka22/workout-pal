import SwiftUI

struct SegmentedProgressBar: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index < filled ? AppColors.accent : AppColors.outline)
                    .frame(height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(min(filled, total)) of \(total) complete")
    }
}

#Preview {
    VStack(spacing: AppSpacing.medium) {
        SegmentedProgressBar(filled: 3, total: 4)
        SegmentedProgressBar(filled: 0, total: 3)
        SegmentedProgressBar(filled: 5, total: 5)
    }
    .padding()
    .background(AppColors.surface)
}
