import SharedUI
import SwiftUI

extension CameraView {
    /// 上のバー(閉じる・フラッシュ・[完了を右上にする案])と、下のバー(倍率・シャッター・撮った枚数・切り替え)。
    var controls: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            zoomPicker
                .padding(.bottom, 20)
            bottomBar
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var topBar: some View {
        HStack {
            circleButton("xmark", label: "閉じる") { onFinish([]) }
            Spacer()
            if viewModel.hasFlash {
                circleButton(viewModel.flashOn ? "bolt.fill" : "bolt.slash.fill", label: "フラッシュ") { viewModel.flashOn.toggle() }
                    .foregroundStyle(viewModel.flashOn ? .yellow : .white)
            }
            if doneButton == .topTrailing { doneLabel }
        }
    }

    private var bottomBar: some View {
        HStack {
            captureCountView
                .frame(maxWidth: .infinity, alignment: .leading)
            shutterButton
            HStack {
                Spacer()
                if doneButton == .bottomTrailing { doneLabel }
                circleButton("arrow.triangle.2.circlepath.camera", label: "インカメラ・アウトカメラの切り替え") {
                    Task { await viewModel.switchCamera() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var zoomPicker: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.zoomPresets, id: \.self) { zoom in
                let isCurrent = abs(viewModel.displayZoom - zoom) < 0.05
                Button { viewModel.setZoom(zoom) } label: {
                    Text(zoom.formatted(.number.precision(.fractionLength(0...1))) + (isCurrent ? "x" : ""))
                        .font(.footnote.bold())
                        .foregroundStyle(isCurrent ? .yellow : .white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.4), in: .circle)
                }
            }
        }
        .opacity(viewModel.zoomPresets.count > 1 ? 1 : 0)
    }

    private var shutterButton: some View {
        Button(action: viewModel.capture) {
            switch shutter {
            case .classic:
                Circle().fill(.white).frame(width: 62, height: 62)
                    .padding(5).overlay(Circle().stroke(.white, lineWidth: 4))
            case .glass:
                Circle().fill(.clear).frame(width: 72, height: 72)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 3))
            }
        }
        .accessibilityLabel("撮影")
    }

    @ViewBuilder
    private var captureCountView: some View {
        let count = viewModel.captured.count
        if count > 0 {
            switch captureCount {
            case .thumbnail:
                if let last = viewModel.captured.last, let image = UIImage(data: last.imageData) {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(alignment: .topTrailing) { badge(count) }
                }
            case .badge:
                badge(count).scaleEffect(1.4)
            }
        }
    }

    private func badge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(.yellow, in: .capsule)
    }

    private var doneLabel: some View {
        Button { onFinish(viewModel.captured) } label: {
            Text("完了").font(.body.bold()).padding(.horizontal, 14).padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .disabled(!viewModel.canFinish)
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
