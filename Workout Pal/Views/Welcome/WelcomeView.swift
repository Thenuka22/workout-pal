import SwiftUI

struct WelcomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: WelcomeViewModel

    init(model: WelcomeViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            switch model.step {
            case .walkthrough:
                walkthrough
            case .signIn:
                signIn
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.step)
        .alert("Couldn't sign in", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var walkthrough: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    model.skipWalkthrough()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
            TabView(selection: $model.walkthroughIndex) {
                ForEach(model.pages) { page in
                    WalkthroughPageView(page: page, pageCount: model.pages.count)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            Button(model.isLastPage ? "Get started" : "Next") {
                model.next()
            }
            .buttonStyle(.primaryAction)
            .padding(.horizontal, AppSpacing.medium)
            PageDots(count: model.pages.count, current: model.walkthroughIndex)
                .padding(.vertical, AppSpacing.large)
        }
    }

    private var signIn: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .strokeBorder(AppColors.outline, lineWidth: 1)
                    .frame(width: 220, height: 220)
                Circle()
                    .strokeBorder(AppColors.accent, lineWidth: 2)
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(AppColors.accentSoft)
                    .frame(width: 112, height: 112)
                Image(systemName: "sparkle")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColors.onAccent)
                    .frame(width: 64, height: 64)
                    .background(AppColors.accent, in: Circle())
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            Spacer(minLength: 0)
            Text("Workout Pal")
                .font(.headline.weight(.bold))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accent)
            Text("Move with purpose.")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
            Text("A little stronger, every day. Your training, movement and progress in one place.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: AppSpacing.small) {
                if model.canUseGoogle {
                    Button {
                        model.signInWithGoogle()
                    } label: {
                        HStack(spacing: AppSpacing.small) {
                            if model.isSigningIn {
                                ProgressView()
                                    .tint(AppColors.onAccent)
                            } else {
                                Image(systemName: "g.circle.fill")
                            }
                            Text("Continue with Google")
                        }
                    }
                    .buttonStyle(.primaryAction)
                    .disabled(model.isSigningIn)
                } else {
                    Label("Google sign-in isn't set up in this build yet. Your workouts stay on this device until it is.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Continue offline") {
                        model.continueOffline()
                    }
                    .buttonStyle(.primaryAction)
                }
                Button("How Workout Pal works") {
                    model.showWalkthrough()
                }
                .buttonStyle(.secondaryAction)
            }
            .padding(.top, AppSpacing.small)
            Text("Signing in needs an internet connection the first time. Your workouts are stored on this device and your Google account is only used to sign in.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.medium)
    }
}

#Preview {
    let container = AppContainer(inMemory: true)
    return WelcomeView(model: container.makeWelcomeViewModel())
}
