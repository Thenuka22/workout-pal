import SwiftUI

struct NumberBadge: View {
    let index: Int

    private var label: String {
        let number = index + 1
        return number < 10 ? "0\(number)" : "\(number)"
    }

    private var color: Color {
        let palette = AppColors.badgePalette
        return palette[index % palette.count]
    }

    var body: some View {
        Text(label)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(AppColors.onAccent)
            .frame(width: 36, height: 36)
            .background(color, in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        NumberBadge(index: 0)
        NumberBadge(index: 1)
        NumberBadge(index: 2)
        NumberBadge(index: 3)
    }
    .padding()
    .background(AppColors.surface)
}
