import AVFoundation
import Domain
import Foundation
import Observation

/// アプリ内カメラの状態。何枚でも続けて撮り、「完了」で撮った写真をまとめて返す。
@MainActor
@Observable
public final class CameraViewModel {
    enum Status { case preparing, ready, denied, unavailable }

    private(set) var status = Status.preparing
    private(set) var captured: [CapturedPhoto] = []
    /// 撮影中(シャッターを押して、位置を求め終えるまで)の枚数。0 になるまで「完了」を押せない。
    private(set) var pending = 0
    var flashOn = false
    private(set) var isFront = false
    private(set) var zoomPresets: [Double] = [1]
    private(set) var maximumZoom = 1.0
    private(set) var displayZoom = 1.0

    let cameraSession = CameraSession()
    private let getLocation: GetCurrentLocationUseCase
    private let saveToLibrary: SavePhotoToLibraryUseCase

    public init(getLocation: GetCurrentLocationUseCase, saveToLibrary: SavePhotoToLibraryUseCase) {
        self.getLocation = getLocation
        self.saveToLibrary = saveToLibrary
    }

    var canFinish: Bool { !captured.isEmpty && pending == 0 }
    var hasFlash: Bool { !isFront && cameraSession.hasFlash }

    /// 許可を確かめて、カメラを動かし始める。
    func start() async {
        var allowed = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            allowed = await AVCaptureDevice.requestAccess(for: .video)
        }
        if allowed {
            await run()
        } else {
            status = .denied
        }
    }

    func stop() {
        cameraSession.stop()
    }

    func switchCamera() async {
        isFront.toggle()
        await run()
    }

    func setZoom(_ zoom: Double) {
        displayZoom = min(max(zoom, zoomPresets.first ?? 1), maximumZoom)
        cameraSession.setZoom(displayZoom)
    }

    func focus(at devicePoint: CGPoint) {
        cameraSession.focus(at: devicePoint)
    }

    /// 1枚撮る。撮った瞬間の現在地を求め、端末の写真ライブラリにも保存する。
    func capture() {
        let takenAt = Date.now
        pending += 1
        Task {
            defer { pending -= 1 }
            guard let data = try? await cameraSession.capture(flashOn: flashOn && hasFlash) else { return }
            let coordinate = await getLocation.execute()
            captured.append(CapturedPhoto(imageData: data, takenAt: takenAt, coordinate: coordinate))
            await saveToLibrary.execute(imageData: data)
        }
    }

    private func run() async {
        do {
            let zoom = try await cameraSession.start(frontFacing: isFront)
            zoomPresets = zoom.presets
            maximumZoom = zoom.maximum
            displayZoom = zoom.presets.contains(1) ? 1 : zoom.presets.first ?? 1
            status = .ready
        } catch {
            status = .unavailable
        }
    }
}
