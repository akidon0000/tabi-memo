import SwiftUI

/// 写真の拡大表示。ピンチで拡大・ダブルタップで切り替え・拡大中はドラッグで移動。下スワイプか×で閉じる。
struct PhotoZoomView: View {
    let image: Image
    var dismiss: () -> Void
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // 黒い背景は、端末の画面角と同じ丸みの角丸にする。ふわっと拡大して出るとき、角丸のカードとして広がる。
            RoundedRectangle(cornerRadius: DeviceMetrics.cornerRadius, style: .continuous)
                .fill(Color.black.opacity(1 - min(max(offset.height, 0) / 500, 0.6)))
                .ignoresSafeArea()
            image
                .resizable()
                .scaledToFit()
                // 等倍で下に引いているときは、引いた量だけ小さくして「離れていく」ことを伝える。
                .scaleEffect(scale * (scale <= 1 ? 1 - min(max(offset.height, 0) / 1500, 0.2) : 1))
                .offset(offset)
        }
        // 写真の上だけでなく、黒い余白のどこをドラッグしても反応するよう、全体に付ける。
        .contentShape(Rectangle())
        .gesture(magnifyGesture)
        .simultaneousGesture(dragGesture)
        .onTapGesture(count: 2) {
            withAnimation(.spring(duration: 0.3)) {
                if scale > 1 { reset() } else { scale = 2.5; baseScale = 2.5 }
            }
        }
        .overlay(alignment: .topTrailing) { closeButton }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { scale = max(baseScale * $0.magnification, 1) }
            .onEnded { _ in
                baseScale = scale
                if scale <= 1.01 { reset() }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(width: baseOffset.width + value.translation.width,
                                    height: baseOffset.height + value.translation.height)
                } else {
                    offset = CGSize(width: 0, height: max(value.translation.height, 0))
                }
            }
            .onEnded { value in
                guard scale <= 1 else {
                    baseOffset = offset
                    return
                }
                // 80pt 以上引くか、下へ勢いよく払ったら閉じる。
                if value.translation.height > 80 || value.predictedEndTranslation.height > 300 {
                    dismiss()
                } else {
                    withAnimation(.spring) { offset = .zero }
                }
            }
    }

    /// パネル全開の閉じるボタンと同じ大きさ(28pt)にそろえる。
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .padding()
        .accessibilityLabel("閉じる")
    }

    private func reset() {
        withAnimation(.spring(duration: 0.3)) {
            scale = 1; baseScale = 1; offset = .zero; baseOffset = .zero
        }
    }
}
