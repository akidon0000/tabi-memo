import SwiftUI

extension CustomSheetView {
    /// 縦のドラッグで段階を変える。指を離した後の慣性を含めた到達点に、一番近い高さへ吸着する。
    func dragGesture(heights: SheetLayout.Heights) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                let w = value.translation.width, h = value.translation.height
                dragTranslation = abs(w) > abs(h) * 1.5 ? 0 : h
            }
            .onEnded { value in
                settleDrag(
                    width: value.translation.width,
                    height: value.translation.height,
                    predictedHeight: value.predictedEndTranslation.height,
                    heights: heights
                )
            }
    }

    /// 全開で、中身のスクロールとパネルの引き下ろしを、1回の指の動きでつなげる。
    /// 中身がいちばん上でないうちは、いつもどおり中身がスクロールする。下へ引いていて中身がいちばん上に着いたら、
    /// そこからは中身を止めて、パネルが指に追従して下がる(着いた時点からの移動量だけ)。離したら、近い段階へ吸着する。
    func pullDownGesture(heights: SheetLayout.Heights) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                guard detent == .full else { return }
                let w = value.translation.width, h = value.translation.height
                defer { pullLastY = h }
                if !isPullingDown {
                    // 縦の動きだけを見る(横は前後の写真のスワイプ)。
                    guard abs(h) > abs(w) * 1.5, scrollOffset <= 0.5 else { return }
                    // 最初からいちばん上なら 0 から、スクロールして上に着いたのなら、その時点から引き始める。
                    if pullLastY == nil {
                        guard h > 0 else { return }
                        pullBase = 0
                    } else {
                        guard h > (pullLastY ?? h) else { return }
                        pullBase = h
                    }
                    isPullingDown = true
                }
                dragTranslation = max(h - pullBase, 0)
            }
            .onEnded { value in
                defer { pullLastY = nil; pullBase = 0; isPullingDown = false }
                guard isPullingDown else { return }
                settleDrag(
                    width: value.translation.width,
                    height: value.translation.height - pullBase,
                    predictedHeight: value.predictedEndTranslation.height - pullBase,
                    heights: heights
                )
            }
    }

    /// 指を離したら、段階の切り替えと移動量の戻しを同じアニメーションで行う。
    /// 別々に行うと、離した瞬間に元の段階の高さへ一度戻ってから動き直し、カクついて見える(FB-4)。
    private func settleDrag(width: CGFloat, height dragHeight: CGFloat, predictedHeight: CGFloat, heights: SheetLayout.Heights) {
        // 横向きのドラッグは前後の写真への移動なので、段階は変えない。
        if abs(width) > abs(dragHeight) * 1.5 {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) { dragTranslation = 0 }
            return
        }
        let projected = height(for: detent, in: heights) - predictedHeight
        let candidates: [(Detent, CGFloat)] = [
            (.compact, heights.compact),
            (.half, heights.half),
            (.full, heights.full),
        ]
        let nearest = candidates.min { abs($0.1 - projected) < abs($1.1 - projected) }?.0 ?? detent
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            detent = nearest
            dragTranslation = 0
        }
    }

    /// 左右スワイプで前後の写真へ。ハーフ・全開のときだけ(コンパクトでは地図の操作と紛れるため移らない)。
    /// 写真は薄くしない(FB-9)。
    func swipeGesture(pageWidth: CGFloat) -> some Gesture {
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
            }
            .onEnded { value in
                guard isSwiping else { return }
                isSwiping = false
                let w = value.translation.width
                let step = w < 0 ? 1 : -1
                let flings = abs(w) > 110 || abs(value.predictedEndTranslation.width) > 260
                if flings, canPage?(step) == true {
                    flingAway(step, pageWidth: pageWidth)
                } else {
                    withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                        pageOffset = 0
                    }
                }
            }
    }

    /// 指を離した向きへ送り、差し替えた次の写真を手前に入れる。
    /// 全開では、隣のページがちょうど元の位置に来るまで1ページぶん滑らせる。ハーフでは、写真を画面の外へ飛ばす。
    private func flingAway(_ step: Int, pageWidth: CGFloat) {
        guard let onPage else { return }
        let slides = slidesPages
        withAnimation(slides ? .easeOut(duration: 0.25) : .easeIn(duration: 0.2)) {
            pageOffset = CGFloat(-step) * (slides ? pageWidth : 520)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(slides ? 250 : 200))
            onPage(step)
            scrollPosition.scrollTo(edge: .top)
            var instant = Transaction()
            instant.disablesAnimations = true
            // 後ろで見えていた写真と入れ替わるので、そのまま手前に出す(点滅させない)。
            // 次の文字はスワイプ中に出し終えているので、入れ替わっても濃さは変えない。
            withTransaction(instant) {
                pageOffset = 0
                pageScale = 1
            }
        }
    }
}
