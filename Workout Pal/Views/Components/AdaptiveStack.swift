import SwiftUI

/// Lays tiles out side by side, or stacked when the text is too large to share a row.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat = AppSpacing.small, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        } else {
            HStack(alignment: .top, spacing: spacing) {
                content
            }
        }
    }
}
