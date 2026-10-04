import SwiftUI

extension CustomSheetView {
    func panel(_ layout: SheetLayout) -> some View {
        let headerHeight = headerHeight(layout)
        let shape = panelShape(layout)

        return ZStack(alignment: .top) {
            // ハーフまでは透明(ガラス越し)、全開で白。スクロール側ではなくここに敷いて、後ろの先読みカードの下にも白が来るようにする。
            Color(.systemBackground).opacity(layout.fullProgress)

            // 前後の写真を後ろに先読みして出す。スワイプ量に応じて手前へ寄ってくる。
            if pageOffset != 0, let snap = neighbor?(peekStep) {
                let topPad = lerp(
                    (config.smallestDetentHeight - compactImageSize) / 2,
                    24 + closeBarHeight * layout.fullProgress,
                    layout.progress
                )
                peekCard(snap, layout: layout, topPad: topPad)
            }

            scrollContent(layout, headerHeight: headerHeight)

            header(layout, height: headerHeight)
        }
        // 左右スワイプで前後の写真へ(ハーフ・全開)。指に追従して傾き、一定以上動かすと飛んでいって次の写真が入る(Tinder 風)。
        .simultaneousGesture(swipeGesture)
        .frame(width: layout.panelWidth, height: layout.panelHeight, alignment: .top)
        .clipShape(shape)
        // Liquid Glass。ヘッダーの色を tint として乗せる。
        .glassEffect(.regular.tint(config.headerTint.opacity(0.3)), in: shape)
    }

    /// 写真の下に出す中身(メモなど)。全開のときだけスクロールでき、写真も一緒に上へ流れる。
    private func scrollContent(_ layout: SheetLayout, headerHeight: CGFloat) -> some View {
        ScrollView(.vertical) {
            content
                .opacity((1 - swipeReveal) * textReveal * layout.fullProgress)
                // スワイプ先のメモも、スワイプ中から同じ位置に重ねて、動いた量に応じて濃くする。
                .overlay(alignment: .top) {
                    if pageOffset != 0, let snap = neighbor?(peekStep) {
                        snap.content
                            .opacity(swipeReveal * layout.fullProgress)
                            .allowsHitTesting(false)
                    }
                }
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
            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
        } action: { _, newValue in
            scrollOffset = newValue
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
