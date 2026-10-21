import SwiftUI

struct RingGauge<Content: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    let content: Content

    init(progress: Double, lineWidth: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.content = content()
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.outline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: progress)
            content
        }
        .padding(lineWidth / 2)
    }
}

extension RingGauge where Content == EmptyView {
    init(progress: Double, lineWidth: CGFloat = 10) {
        self.init(progress: progress, lineWidth: lineWidth) {
            EmptyView()
        }
    }
}

#Preview {
    HStack(spacing: AppSpacing.large) {
        RingGauge(progress: 0.75) {
            Text("42")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(width: 96, height: 96)
        RingGauge(progress: 0.3, lineWidth: 6)
            .frame(width: 48, height: 48)
    }
    .padding()
    .background(AppColors.surface)
}
