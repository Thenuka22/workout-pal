import Accessibility
import Foundation
import SwiftUI
import UIKit

struct RepCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var model: RepCounterViewModel
    private let onAccept: (Int) -> Void

    init(model: RepCounterViewModel, onAccept: @escaping (Int) -> Void = { _ in }) {
        _model = State(initialValue: model)
        self.onAccept = onAccept
    }

    var body: some View {
        Group {
            if let exercise = model.exercise {
                counter(for: exercise)
            } else {
                chooser
            }
        }
        .screenBackground()
        .navigationTitle(model.exercise?.title ?? "Camera rep counter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .toolbar {
            if !voiceOverEnabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.toggleSpeech()
                    } label: {
                        Image(systemName: model.isSpeaking ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    .accessibilityLabel(model.isSpeaking ? "Stop saying reps out loud" : "Say reps out loud")
                }
            }
            if model.canChangeExercise && model.exercise != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Change") {
                        model.changeExercise()
                    }
                }
            }
        }
        .alert("Could not save reps", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: model.acceptedReps) { _, reps in
            if let reps {
                onAccept(reps)
                dismiss()
            }
        }
        .onDisappear {
            model.disappear()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                model.sceneDidEnterBackground()
            case .active:
                model.sceneDidBecomeActive()
            default:
                break
            }
        }
    }

    private var chooser: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Pick an exercise. Workout Pal uses on-device pose detection to count your reps, and you check the count before it is saved.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                ForEach(model.exercises) { exercise in
                    OptionCard(
                        title: exercise.title,
                        subtitle: exercise.summary,
                        symbolName: exercise.symbolName,
                        isSelected: false
                    ) {
                        model.select(exercise)
                    }
                }
                Label("Only squats and jumping jacks can be counted. Log other exercises by hand.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private func counter(for exercise: CameraExercise) -> some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    cameraPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ScrollView {
                        controls(for: exercise)
                    }
                    .frame(width: 360)
                }
                .padding(AppSpacing.medium)
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        cameraPanel
                            .frame(height: 440)
                        controls(for: exercise)
                    }
                    .padding(AppSpacing.medium)
                }
            }
        }
        .onAppear {
            model.appear()
        }
    }

    private var cameraPanel: some View {
        ZStack(alignment: .topLeading) {
            Color.black
            if model.cameraState == .idle || model.isCameraActive {
                CameraPreview(session: model.captureSession, isRunning: model.cameraState == .running)
                PoseOverlay(frame: model.latestFrame, isTracking: model.trackingStatus.isTracking)
            }
            switch model.cameraState {
            case .idle, .starting:
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .running:
                EmptyView()
            case .denied:
                cameraMessage(
                    title: "Camera access is off",
                    message: "Allow camera access in Settings to count reps, or log your sets by hand.",
                    actionTitle: "Open Settings",
                    action: openSettings
                )
            case .unavailable:
                cameraMessage(
                    title: "No camera available",
                    message: "This device can't count reps. You can still log your sets by hand.",
                    actionTitle: nil,
                    action: {}
                )
            case .failed(let message):
                cameraMessage(title: "Camera stopped", message: message, actionTitle: "Try again") {
                    model.startCamera()
                }
            }
            if model.cameraState == .running {
                trackingPill
                    .padding(AppSpacing.small)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Camera preview")
    }

    private var trackingPill: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Circle()
                .fill(AppColors.onAccent)
                .frame(width: 8, height: 8)
            Text("Vision · \(model.trackingStatus.title)")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
        }
        .foregroundStyle(AppColors.onAccent)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(pillColor, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tracking status: \(model.trackingStatus.title)")
    }

    private var pillColor: Color {
        switch model.trackingStatus {
        case .tracking: AppColors.accent
        case .adjusting: AppColors.warning
        case .searching: AppColors.textSecondary
        }
    }

    private func controls(for exercise: CameraExercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if model.isReviewing {
                reviewCard(for: exercise)
            } else {
                countCard(for: exercise)
            }
            savedSetsCard
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(model.trackingStatus.title)
                    .eyebrow()
                Text(model.trackingStatus.message)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .card()
            setupCard(for: exercise)
        }
    }

    private func countCard(for exercise: CameraExercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(exercise.title)
                .eyebrow()
            repCount(model.detectedReps)
            if model.isCounting {
                Text(model.countingHint)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                Button {
                    model.stopCounting()
                } label: {
                    Label("Stop and review", systemImage: "stop.fill")
                }
                .buttonStyle(.secondaryAction)
            } else {
                Button {
                    model.startCounting()
                } label: {
                    Label("Start counting", systemImage: "play.fill")
                }
                .buttonStyle(.primaryAction)
                .disabled(!model.canStartCounting)
            }
        }
        .card()
        .onChange(of: model.detectedReps) { _, reps in
            if reps > 0 && model.isCounting {
                AccessibilityNotification.Announcement("\(reps)").post()
            }
        }
    }

    private func reviewCard(for exercise: CameraExercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Check your count")
                .eyebrow()
            Text("The camera counted \(model.detectedReps). Change the number if it missed a rep or added one.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                repCount(model.reviewedReps)
                Spacer()
                Stepper("Reps", value: $model.reviewedReps, in: 0...500)
                    .labelsHidden()
            }
            Button(model.acceptTitle) {
                model.acceptReps()
            }
            .buttonStyle(.primaryAction)
            .disabled(model.reviewedReps == 0)
            Button("Discard", role: .destructive) {
                model.discardReview()
            }
            .buttonStyle(.secondaryAction)
        }
        .card()
    }

    private func repCount(_ reps: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Text("\(reps)")
                .metric(size: 56)
                .foregroundStyle(AppColors.textPrimary)
                .contentTransition(.numericText())
            Text(reps == 1 ? "rep" : "reps")
                .font(.headline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var savedSetsCard: some View {
        if !model.savedSets.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Saved to your history")
                    .eyebrow()
                ForEach(Array(model.savedSets.enumerated()), id: \.element.id) { index, set in
                    HStack {
                        Text("Set \(index + 1)")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(set.reps) reps")
                            .foregroundStyle(AppColors.textPrimary)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.accent)
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                }
                Text("Start counting again to add another set.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .card()
        }
    }

    private func setupCard(for exercise: CameraExercise) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Set up")
                .eyebrow()
            ForEach(Array(exercise.setupTips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.onAccent)
                        .frame(width: 22, height: 22)
                        .background(AppColors.accent, in: Circle())
                        .accessibilityHidden(true)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Video stays on this device. Counting pauses whenever you leave the frame.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private func cameraMessage(
        title: String,
        message: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "video.slash.fill")
                .font(.largeTitle)
                .foregroundStyle(AppColors.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
