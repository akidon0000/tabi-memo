import AVFoundation
import SwiftUI
import UIKit

/// カメラのプレビュー。タップした点を、カメラの座標(0〜1)にして渡す。
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let onTap: (_ devicePoint: CGPoint, _ layerPoint: CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped)))
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class PreviewUIView: UIView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) { nil }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }

    final class Coordinator: NSObject {
        var onTap: (CGPoint, CGPoint) -> Void
        weak var view: PreviewUIView?

        init(onTap: @escaping (CGPoint, CGPoint) -> Void) {
            self.onTap = onTap
        }

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            guard let view else { return }
            let point = recognizer.location(in: view)
            onTap(view.previewLayer.captureDevicePointConverted(fromLayerPoint: point), point)
        }
    }
}
