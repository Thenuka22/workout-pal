import SwiftUI

struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppColors.onAccent : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(isSelected ? AppColors.accent : AppColors.surfaceElevated, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : AppColors.outline, lineWidth: 1)
                }
                .padding(.vertical, AppSpacing.xSmall)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ChipPicker<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.small) {
                ForEach(options) { option in
                    Chip(title: title(option), isSelected: option == selection) {
                        selection = option
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct TagPill: View {
    let text: String
    var symbolName: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            if let symbolName {
                Image(systemName: symbolName)
            }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, AppSpacing.small + AppSpacing.xSmall)
        .padding(.vertical, AppSpacing.xSmall + 2)
        .background(AppColors.surfaceElevated, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(AppColors.outline, lineWidth: 1)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.medium) {
        HStack {
            Chip(title: "For you", isSelected: true) {}
            Chip(title: "Strength", isSelected: false) {}
            Chip(title: "Mobility", isSelected: false) {}
        }
        HStack {
            TagPill(text: "32 min", symbolName: "clock")
            TagPill(text: "Intermediate")
            TagPill(text: "5 exercises")
        }
    }
    .padding()
    .background(AppColors.surface)
}
