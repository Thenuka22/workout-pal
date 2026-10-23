import Foundation
import SwiftUI
import UIKit

struct RepCounterView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var model: RepCounterViewModel

    init(model: RepCounterViewModel) {
        _model = State(initialValue: model)
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
            if model.canChangeExercise && model.exercise != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Change") {
                        model.changeExercise()
                    }
                }
            }
        }
        .onDisappear {
            model.stopCamera()
        }
        .onChange(of: scenePhase) { _, phase in
            model.scenePhaseChanged(isActive: phase == .active)
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

    @ViewBuilder
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
            model.startCamera()
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
                .fill(pillColor)
                .frame(width: 8, height: 8)
            Text("Vision · \(model.trackingStatus.title)")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
        }
        .foregroundStyle(AppColors.onAccent)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(pillColor.opacity(0.9), in: Capsule())
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
            countCard(for: exercise)
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
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Text("\(model.detectedReps)")
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.textPrimary)
                    .contentTransition(.numericText())
                Text("reps")
                    .font(.headline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            if model.isCounting {
                Text(model.countingHint)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                Button {
                    model.stopCounting()
                } label: {
                    Label("Stop counting", systemImage: "stop.fill")
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
            if reps > 0 {
                AccessibilityNotification.Announcement("\(reps)").post()
            }
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
