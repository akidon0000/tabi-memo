import AVFoundation
import Foundation

/// AVFoundation のカメラ。セッションの操作は専用のキューで行う(メインを止めないため)。
/// 画面からは `CameraViewModel` を通して使う。
nonisolated final class CameraSession: NSObject, @unchecked Sendable {
    /// プレビューが映す対象。
    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "com.akidon0000.tabimemo.camera")
    private let output = AVCapturePhotoOutput()
    private var device: AVCaptureDevice?
    private var captures: [Int64: CheckedContinuation<Data, Error>] = [:]

    enum CameraError: Error { case noCamera, captureFailed }

    /// 切り替えられる倍率(表示上の倍率。0.5・1・3 など)と、ピンチで届く最大。
    struct Zoom: Sendable {
        var presets: [Double]
        var maximum: Double
    }

    /// 向きを選んでセッションを組み、動かし始める。映せるカメラが無ければ throw。
    func start(frontFacing: Bool) async throws -> Zoom {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try self.configure(frontFacing: frontFacing))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        queue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    /// 表示上の倍率にする。
    func setZoom(_ displayZoom: Double) {
        queue.async {
            guard let device = self.device else { return }
            let multiplier = Double(device.displayVideoZoomFactorMultiplier)
            let factor = min(max(displayZoom / multiplier, Double(device.minAvailableVideoZoomFactor)), Double(device.maxAvailableVideoZoomFactor))
            try? device.lockForConfiguration()
            device.videoZoomFactor = CGFloat(factor)
            device.unlockForConfiguration()
        }
    }

    /// プレビュー上の点(0〜1)にピントと露出を合わせる。
    func focus(at devicePoint: CGPoint) {
        queue.async {
            guard let device = self.device else { return }
            try? device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        }
    }

    /// 1枚撮って、JPEG のデータを返す。
    func capture(flashOn: Bool) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                if flashOn, self.output.supportedFlashModes.contains(.on) { settings.flashMode = .on }
                self.captures[settings.uniqueID] = continuation
                self.output.connection(with: .video)?.videoRotationAngle = 90
                self.output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    var hasFlash: Bool { device?.hasFlash ?? false }

    // MARK: - 組み立て(キューの上で呼ぶ)

    private func configure(frontFacing: Bool) throws -> Zoom {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        session.inputs.forEach(session.removeInput)
        guard let camera = Self.camera(frontFacing: frontFacing), let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { throw CameraError.noCamera }
        session.addInput(input)
        if !session.outputs.contains(output), session.canAddOutput(output) { session.addOutput(output) }
        device = camera
        try camera.lockForConfiguration()
        camera.videoZoomFactor = CGFloat(1 / Double(camera.displayVideoZoomFactorMultiplier))
        camera.unlockForConfiguration()
        if !session.isRunning { session.startRunning() }
        return Self.zoom(of: camera)
    }

    /// 背面は、使えるなかで最も多くのレンズをまとめたカメラ(超広角・広角・望遠を倍率で切り替えられる)。
    private static func camera(frontFacing: Bool) -> AVCaptureDevice? {
        if frontFacing { return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) }
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
        return types.lazy.compactMap { AVCaptureDevice.default($0, for: .video, position: .back) }.first
    }

    /// 倍率の候補。いちばん広い倍率(超広角があれば 0.5)と、レンズが切り替わる倍率。
    private static func zoom(of device: AVCaptureDevice) -> Zoom {
        let multiplier = Double(device.displayVideoZoomFactorMultiplier)
        let minimum = Double(device.minAvailableVideoZoomFactor) * multiplier
        let switchovers = device.virtualDeviceSwitchOverVideoZoomFactors.map { Double(truncating: $0) * multiplier }
        let presets = ([minimum] + switchovers).map { ($0 * 10).rounded() / 10 }
        let unique = presets.reduce(into: [Double]()) { result, value in if !result.contains(value) { result.append(value) } }
        return Zoom(presets: unique, maximum: min(Double(device.maxAvailableVideoZoomFactor) * multiplier, 10))
    }
}

extension CameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let id = photo.resolvedSettings.uniqueID
        let data = photo.fileDataRepresentation()
        queue.async {
            guard let continuation = self.captures.removeValue(forKey: id) else { return }
            if let data, error == nil {
                continuation.resume(returning: data)
            } else {
                continuation.resume(throwing: error ?? CameraError.captureFailed)
            }
        }
    }
}
