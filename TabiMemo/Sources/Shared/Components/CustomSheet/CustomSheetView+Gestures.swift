import SwiftUI

extension CustomSheetView {
    /// 縦のドラッグで段階を変える。指を離した後の慣性を含めた到達点に、一番近い高さへ吸着する。
    func dragGesture(heights: SheetLayout.Heights) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($dragTranslation) { value, state, _ in
                let w = value.translation.width, h = value.translation.height
                state = abs(w) > abs(h) * 1.5 ? 0 : h
            }
            .onEnded { value in
                // 横向きのドラッグは前後の写真への移動なので、段階は変えない。
                if abs(value.translation.width) > abs(value.translation.height) * 1.5 { return }
                let projected = height(for: detent, in: heights) - value.predictedEndTranslation.height
                let candidates: [(Detent, CGFloat)] = [
                    (.compact, heights.compact),
                    (.half, heights.half),
                    (.full, heights.full),
                ]
                let nearest = candidates.min { abs($0.1 - projected) < abs($1.1 - projected) }?.0 ?? detent
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    detent = nearest
                }
            }
    }

    /// 左右スワイプで前後の写真へ。ハーフ・全開のときだけ(コンパクトでは地図の操作と紛れるため移らない)。
    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .global)
            .onChanged { value in
                guard detent != .compact else { return }
                let w = value.translation.width, h = value.translation.height
                if !isSwiping {
                    guard abs(w) > 12, abs(w) > abs(h) * 1.5 else { return }
                    isSwiping = true
                }
                peekStep = w < 0 ? 1 : -1
                // 移れない向き(端)では、抵抗をつけて少ししか動かさない。
                let hasNeighbor = canPage?(w < 0 ? 1 : -1) == true
                pageOffset = hasNeighbor ? w : w * 0.3
                pageOpacity = 1 - min(abs(pageOffset) / 500, 0.5)
            }
            .onEnded { value in
                guard isSwiping else { return }
                isSwiping = false
                let w = value.translation.width
                let step = w < 0 ? 1 : -1
                let flings = abs(w) > 110 || abs(value.predictedEndTranslation.width) > 260
                if flings, canPage?(step) == true {
                    flingAway(step)
                } else {
                    withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                        pageOffset = 0
                        pageOpacity = 1
                    }
                }
            }
    }

    /// 指を離した向きへ飛ばして消し、差し替えた次の写真を手前に入れる。
    private func flingAway(_ step: Int) {
        guard let onPage else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            pageOffset = CGFloat(-step) * 520
            pageOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            onPage(step)
            scrollPosition.scrollTo(edge: .top)
            var instant = Transaction()
            instant.disablesAnimations = true
            // 後ろで見えていた写真と入れ替わるので、そのまま手前に出す(点滅させない)。
            // 次の文字はスワイプ中に出し終えているので、入れ替わっても濃さは変えない。
            withTransaction(instant) {
                pageOffset = 0
                pageOpacity = 1
                pageScale = 1
            }
        }
    }
}
