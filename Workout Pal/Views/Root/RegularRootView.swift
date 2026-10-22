import Foundation
import SwiftUI

struct RegularRootView: View {
    @Binding var selection: AppDestination?
    let displayName: String

    private var initial: String {
        let letter = displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()
        return letter.isEmpty ? "W" : letter
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(AppDestination.allCases) { destination in
                        Label(sidebarTitle(for: destination), systemImage: destination.symbolName)
                            .font(.body.weight(destination == selection ? .semibold : .regular))
                            .foregroundStyle(destination == selection ? AppColors.accent : AppColors.textPrimary)
                            .tag(destination)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                    .fill(destination == selection ? AppColors.accentSoft : Color.clear)
                            )
                    }
                } header: {
                    Text("Training space")
                        .eyebrow()
                }
                Section {
                    Button {
                        selection = .profile
                    } label: {
                        HStack(spacing: AppSpacing.small) {
                            AvatarBadge(initial: initial, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayName.isEmpty ? "Your profile" : displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Personal plan")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Account")
                        .eyebrow()
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(AppColors.surface)
            .safeAreaInset(edge: .top) {
                Text("Workout Pal")
                    .font(.headline.weight(.bold))
                    .kerning(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColors.surface)
            }
            .toolbar(.hidden, for: .navigationBar)
        } detail: {
            NavigationStack {
                DestinationView(destination: selection ?? .home)
            }
        }
    }

    private func sidebarTitle(for destination: AppDestination) -> String {
        switch destination {
        case .home: "Overview"
        case .train: "Workouts"
        case .progress: "Progress"
        case .profile: "Profile"
        }
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return RegularRootView(selection: .constant(.home), displayName: "Induwara")
        .environment(container)
        .environment(AppNavigation())
}
