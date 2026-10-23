import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let isRunning: Bool

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.attach(session)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.updateRotation()
    }
}

final class CameraPreviewView: UIView {
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func attach(_ session: AVCaptureSession) {
        previewLayer.session = session
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
        updateRotation()
    }

    func updateRotation() {
        if rotationCoordinator == nil,
           let input = previewLayer.session?.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first {
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: input.device, previewLayer: previewLayer)
        }
        guard let rotationCoordinator, let connection = previewLayer.connection else {
            return
        }
        let angle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    private func configure() {
        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspect
        layer.addSublayer(previewLayer)
    }
}
