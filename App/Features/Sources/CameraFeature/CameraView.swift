import Domain
import SharedUI
import SwiftUI

/// アプリ内カメラ。何枚でも続けて撮り、「完了」で撮った写真をまとめて渡す。
public struct CameraView: View {
    @State var viewModel: CameraViewModel
    /// 閉じるとき。「完了」なら撮った写真、閉じるだけなら空。
    let onFinish: ([CapturedPhoto]) -> Void

    @AppStorage(AppearanceKey.shutter) var shutter = ShutterStyle.classic
    @AppStorage(AppearanceKey.doneButton) var doneButton = DoneButtonPlacement.bottomTrailing
    @AppStorage(AppearanceKey.captureCount) var captureCount = CaptureCountStyle.thumbnail
    @State private var baseZoom: Double?
    @State private var focusMark: CGPoint?

    public init(viewModel: CameraViewModel, onFinish: @escaping ([CapturedPhoto]) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .preparing:
            ProgressView().tint(.white)
        case .denied:
            message("カメラの使用が許可されていません。設定アプリで許可してください。", showsSettings: true)
        case .unavailable:
            message("カメラを使えません。", showsSettings: false)
        case .ready:
            ZStack {
                preview
                controls
            }
        }
    }

    private var preview: some View {
        CameraPreviewView(session: viewModel.cameraSession.session) { devicePoint, layerPoint in
            viewModel.focus(at: devicePoint)
            focusMark = layerPoint
            Task {
                try? await Task.sleep(for: .seconds(1))
                focusMark = nil
            }
        }
        .ignoresSafeArea()
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let base = baseZoom ?? viewModel.displayZoom
                    baseZoom = base
                    viewModel.setZoom(base * value.magnification)
                }
                .onEnded { _ in baseZoom = nil }
        )
        .overlay {
            if let focusMark {
                Rectangle()
                    .stroke(.yellow, lineWidth: 1.5)
                    .frame(width: 72, height: 72)
                    .position(focusMark)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: focusMark)
    }

    private func message(_ text: String, showsSettings: Bool) -> some View {
        VStack(spacing: 16) {
            Text(text).multilineTextAlignment(.center)
            if showsSettings {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .buttonStyle(.glass)
            }
            Button("閉じる") { onFinish([]) }
                .buttonStyle(.glass)
        }
        .padding(32)
    }
}
