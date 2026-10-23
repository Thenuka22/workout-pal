import SwiftUI

struct PoseOverlay: View {
    let frame: PoseFrame?
    let isTracking: Bool

    var body: some View {
        let frame = frame
        let color = isTracking ? AppColors.accent : AppColors.warning
        return Canvas { context, size in
            guard let frame else {
                return
            }
            let rect = Self.fittedRect(aspectRatio: frame.aspectRatio, in: size)
            for bone in PoseBone.skeleton {
                guard let start = Self.location(of: bone.from, in: frame, rect: rect),
                      let end = Self.location(of: bone.to, in: frame, rect: rect)
                else {
                    continue
                }
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            for joint in BodyJoint.allCases {
                guard let point = Self.location(of: joint, in: frame, rect: rect) else {
                    continue
                }
                let dot = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: dot), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    nonisolated private static func location(of joint: BodyJoint, in frame: PoseFrame, rect: CGRect) -> CGPoint? {
        guard let point = frame.point(joint) else {
            return nil
        }
        return CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
    }

    nonisolated static func fittedRect(aspectRatio: Double, in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, aspectRatio > 0 else {
            return .zero
        }
        if size.width / size.height > aspectRatio {
            let width = size.height * aspectRatio
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }
        let height = size.width / aspectRatio
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }
}
