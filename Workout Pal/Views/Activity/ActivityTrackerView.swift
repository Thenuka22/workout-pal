import Foundation
import SwiftUI
import UIKit

struct ActivityTrackerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var model: ActivityTrackerViewModel
    @State private var isConfirmingDiscard = false

    init(model: ActivityTrackerViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
            if !model.isAvailable {
                ContentUnavailableView(
                    "Step counting isn't available",
                    systemImage: "figure.walk.motion",
                    description: Text("This device has no motion sensors for steps. Try Workout Pal on an iPhone.")
                )
            } else if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    ScrollView {
                        measurements
                    }
                    .frame(maxWidth: .infinity)
                    ScrollView {
                        VStack(spacing: AppSpacing.medium) {
                            controls
                            aboutCard
                        }
                    }
                    .frame(width: 360)
                }
                .padding(AppSpacing.medium)
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.medium) {
                        measurements
                        controls
                        aboutCard
                    }
                    .padding(AppSpacing.medium)
                }
            }
        }
        .screenBackground()
        .navigationTitle("Walk & run")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.surface, for: .navigationBar)
        .toolbar {
            if model.activity != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Discard", role: .destructive) {
                        isConfirmingDiscard = true
                    }
                }
            }
        }
        .confirmationDialog("Discard this session?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("Discard session", role: .destructive) {
                model.discard()
            }
            Button("Keep tracking", role: .cancel) {}
        } message: {
            Text("The steps and time from this session won't be saved.")
        }
        .alert("Motion tracking stopped", isPresented: $model.isShowingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
        .task {
            await model.load()
        }
        .onChange(of: scenePhase) { _, phase in
            model.scenePhaseChanged(isActive: phase == .active)
        }
    }

    @ViewBuilder
    private var measurements: some View {
        if let finished = model.finishedActivity {
            ActivitySummaryCard(activity: finished, units: model.units)
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack {
                        Text(model.statusTitle)
                            .eyebrow()
                        Spacer()
                        if let activity = model.activity {
                            TagPill(text: activity.kind.title, symbolName: activity.kind.symbolName)
                        }
                    }
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                        Text(Formatting.steps(model.steps))
                            .metric(size: 56)
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("steps")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .card()
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        StatTile(
                            title: "Active time",
                            value: Formatting.elapsed(seconds: model.elapsedSeconds(at: context.date)),
                            dotColor: AppColors.infoBlue
                        )
                    }
                    StatTile(
                        title: "Distance",
                        value: model.distanceText,
                        caption: "estimated",
                        dotColor: AppColors.infoOrange
                    )
                }
                StatTile(
                    title: "Detected motion",
                    value: model.detectedText,
                    caption: model.activity.map { "You chose \($0.kind.title.lowercased())" },
                    dotColor: AppColors.infoPurple
                )
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if model.finishedActivity != nil {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label("Saved to your history", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
                Button {
                    model.startAnother()
                } label: {
                    Label("Start another", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.primaryAction)
            }
        } else if model.activity == nil {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Session type")
                    .eyebrow()
                ChipPicker(options: model.kinds, selection: $model.kind) { $0.title }
                if model.isAccessBlocked {
                    Label("Motion & Fitness access is off. Turn it on in Settings to track walks and runs.", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.warning)
                    Button("Open Settings", action: openSettings)
                        .buttonStyle(.secondaryAction)
                }
                Button {
                    model.start()
                } label: {
                    Label(model.startTitle, systemImage: "play.fill")
                }
                .buttonStyle(.primaryAction)
                .disabled(model.isStarting)
            }
            .card()
        } else {
            HStack(spacing: AppSpacing.small) {
                Button {
                    if model.isPaused {
                        model.resume()
                    } else {
                        model.pause()
                    }
                } label: {
                    Label(model.isPaused ? "Resume" : "Pause", systemImage: model.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.secondaryAction)
                Button {
                    model.finish()
                } label: {
                    Label("Finish", systemImage: "flag.checkered")
                }
                .buttonStyle(.primaryAction)
                .disabled(model.isFinishing)
            }
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("How it works")
                .eyebrow()
            Text("Steps and distance come from your phone's motion sensors. Distance is an estimate and no GPS route is recorded.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
            Text("Keep your phone with you. If Workout Pal is in the background, your steps are caught up when you come back.")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .card()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

struct ActivitySummaryCard: View {
    let activity: ActivitySession
    let units: UnitPreference

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("\(activity.kind.title) complete")
                    .eyebrow()
                Text(Formatting.dateTime(activity.startedAt))
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .card()
            HStack(alignment: .top, spacing: AppSpacing.small) {
                StatTile(title: "Steps", value: Formatting.steps(activity.steps), dotColor: AppColors.accent)
                StatTile(
                    title: "Active time",
                    value: Formatting.elapsed(seconds: activity.activeSeconds),
                    dotColor: AppColors.infoBlue
                )
            }
            HStack(alignment: .top, spacing: AppSpacing.small) {
                StatTile(
                    title: "Distance",
                    value: activity.distanceMeters.map { Formatting.distance(meters: $0, units: units) } ?? "Unavailable",
                    caption: "estimated",
                    dotColor: AppColors.infoOrange
                )
                StatTile(
                    title: "Detected",
                    value: activity.detectedMotion?.title ?? "Unavailable",
                    caption: "you chose \(activity.kind.title.lowercased())",
                    dotColor: AppColors.infoPurple
                )
            }
        }
    }
}
