import SwiftUI

extension CustomSheetView {
    func panel(_ layout: SheetLayout) -> some View {
        let headerHeight = headerHeight(layout)
        let shape = panelShape(layout)

        return ZStack(alignment: .top) {
            // ハーフまでは透明(ガラス越し)、全開で白。スクロール側ではなくここに敷いて、後ろの先読みカードの下にも白が来るようにする。
            Color(.systemBackground).opacity(layout.fullProgress)

            scrollContent(layout, headerHeight: headerHeight)

            // ハーフで、前後の写真を手前の写真の後ろに先読みして出す。全開ではヘッダー層に並べる(+Header)。
            if !slidesPages, pageOffset != 0, let snap = neighbor?(peekStep) {
                let topPad = lerp(
                    (config.smallestDetentHeight - compactImageSize) / 2,
                    24 + closeBarHeight * layout.fullProgress,
                    layout.progress
                )
                peekCard(snap, layout: layout, topPad: topPad)
            }

            header(layout, height: headerHeight)
        }
        // 左右スワイプで前後の写真へ(ハーフ・全開)。指に追従して傾き、一定以上動かすと飛んでいって次の写真が入る(Tinder 風)。
        .simultaneousGesture(swipeGesture(pageWidth: layout.panelWidth))
        .frame(width: layout.panelWidth, height: layout.panelHeight, alignment: .top)
        .clipShape(shape)
        // Liquid Glass。ヘッダーの色を tint として乗せる。
        .glassEffect(.regular.tint(config.headerTint.opacity(0.3)), in: shape)
    }

    /// 写真の下に出す中身(メモなど)。全開のときだけスクロールでき、写真も一緒に上へ流れる。
    private func scrollContent(_ layout: SheetLayout, headerHeight: CGFloat) -> some View {
        ScrollView(.vertical) {
            content
                // 全開では写真と一緒に横へ動く。ハーフでは動かさず、スワイプ量に応じて薄くする。
                .offset(x: slidesPages ? pageOffset : 0)
                .opacity((slidesPages ? 1 : 1 - swipeReveal) * textReveal * layout.fullProgress)
                .overlay(alignment: .top) { neighborContent(layout) }
                .padding(.top, headerHeight)
                .overlay(alignment: .top) {
                    // 全開ではヘッダー層がタッチを通すので、写真の位置に透明なタップ領域を置く。
                    Color.clear
                        .frame(height: layout.expandedImageHeight)
                        .contentShape(Rectangle())
                        .onTapGesture { onImageTap?() }
                        .padding(.top, 24 + closeBarHeight)
                        .allowsHitTesting(detent == .full)
                }
                .overlay(alignment: .top) {
                    fullActionHitArea(layout)
                }
        }
        .scrollPosition($scrollPosition)
        .scrollDisabled(detent != .full)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollOffset = max(offset, 0)
            // 全開で、いちばん上からさらに下へ引いたら、パネルを閉じる(FB-8)。
            if offset < -pullToCloseDistance, detent == .full, isScrollInteracting { collapse() }
        }
        .onScrollPhaseChange { _, phase in
            isScrollInteracting = phase == .interacting
        }
    }

    /// スワイプ先のメモ。全開では隣のページの位置に置いて一緒に滑らせる。ハーフでは同じ位置に重ね、動いた量に応じて濃くする。
    @ViewBuilder
    private func neighborContent(_ layout: SheetLayout) -> some View {
        if pageOffset != 0, let snap = neighbor?(peekStep) {
            snap.content
                .opacity((slidesPages ? 1 : swipeReveal) * layout.fullProgress)
                // 写真の高さの違いだけ上下をずらし、スクロールする前の位置で見せる(入れ替わると一番上から表示するため)。
                .offset(
                    x: slidesPages ? neighborOffset(layout) : 0,
                    y: slidesPages ? layout.nextImageHeight - layout.ownImageHeight + scrollOffset : 0
                )
                .allowsHitTesting(false)
                .transition(.identity)
        }
    }

    /// 全開では、見た目は上の層のボタンが担い、押すのは、ここに置く透明なボタン2つ(スクロールと一緒に動く)。
    /// 画像のタップ領域より手前に置く。
    @ViewBuilder
    private func fullActionHitArea(_ layout: SheetLayout) -> some View {
        if detent == .full, onEdit != nil {
            HStack(spacing: 0) {
                Button { onEdit?() } label: { Color.clear.frame(width: 48, height: actionButtonHeight).contentShape(Rectangle()) }
                Button { onDelete?() } label: { Color.clear.frame(width: 48, height: actionButtonHeight).contentShape(Rectangle()) }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, headerPadding)
            .padding(.trailing, 8)
            .padding(.top, actionButtonsTop(barHeight: closeBarHeight, imageHeight: layout.ownImageHeight) + 24)
        }
    }

    /// コンパクトはカプセル、広がるにつれて端末の画面角に同心の丸みへ移る。全開では角丸なし。
    /// パネルの角の半径(全開で 0 にする前の値)。
    func panelRadius(progress: CGFloat) -> CGFloat {
        let capsule = config.smallestDetentHeight / 2
        let concentric = max(DeviceMetrics.cornerRadius - expandedMargin, 0)
        return lerp(capsule, concentric, progress)
    }

    private func panelShape(_ layout: SheetLayout) -> UnevenRoundedRectangle {
        let radius = panelRadius(progress: layout.progress) * (1 - layout.fullProgress)
        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: radius,
            bottomTrailingRadius: radius,
            topTrailingRadius: radius
        )
    }
}
