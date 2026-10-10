import SharedUI
import SwiftUI

extension CustomSheetView {
    /// 1回の描画ぶんの大きさをまとめて求める。
    func layout(in size: CGSize) -> SheetLayout {
        let heights = detentHeights(in: size)
        let panelHeight = min(max(height(for: detent, in: heights) - dragTranslation, heights.compact), heights.full)
        let progress = min(max((panelHeight - heights.compact) / (heights.half - heights.compact), 0), 1)
        let fullProgress = min(max((panelHeight - heights.half) / (heights.full - heights.half), 0), 1)

        // 全開に近づくほど余白と角丸をなくして、画面いっぱいにする。
        let edge = 1 - fullProgress
        let margin = lerp(compactMargin, expandedMargin, progress) * edge
        let reserve = onAdd == nil ? 0 : (addButtonSize + addButtonGap) * max(1 - progress * 3, 0)
        let expandedImageWidth = size.width - margin * 2 - headerPadding * 2
        // 写真の縦横比どおりの高さにする。ハーフでは見切れない範囲、全開では画面の約6割までに収める。
        let halfCap = halfImageCap(fullHeight: heights.full)
        let imageCap = lerp(halfCap, max(heights.full * 0.6, halfCap), fullProgress)
        let ownImageHeight = imageHeight(aspectRatio: headerAspectRatio, width: expandedImageWidth, cap: imageCap)
        // スワイプ先の写真の高さ。スワイプ量に応じて、レイアウト(文字の位置・パネル内の高さ)を先に移す。
        let nextImageHeight = neighborImageHeight(width: expandedImageWidth, cap: imageCap) ?? ownImageHeight

        return SheetLayout(
            heights: heights,
            panelHeight: panelHeight,
            panelWidth: size.width - margin * 2 - reserve,
            progress: progress,
            fullProgress: fullProgress,
            margin: margin,
            bottomMargin: lerp(28, 8, progress) * edge,
            expandedImageWidth: expandedImageWidth,
            // 全開では写真と文字が一緒に横へ動くので、文字の位置はスワイプ先へ寄せない。
            expandedImageHeight: slidesPages ? ownImageHeight : lerp(ownImageHeight, nextImageHeight, swipeReveal),
            ownImageHeight: ownImageHeight,
            nextImageHeight: nextImageHeight
        )
    }

    /// スワイプ量に応じた、スワイプ先の見え具合(0〜1)。
    var swipeReveal: CGFloat { min(abs(pageOffset) / 160, 1) }

    /// 全開では、前後の写真へ移るとき、写真・日時・メモを1枚のページとして一緒に横へ動かす(FB-7)。
    /// ハーフでは、写真だけが傾きながら飛んでいく(ADR 0005)。
    var slidesPages: Bool { detent == .full }

    /// 全開のスライドで、隣のページを置く横の位置。次のページは右から、前のページは左から入ってくる。
    func neighborOffset(_ layout: SheetLayout) -> CGFloat {
        pageOffset + CGFloat(peekStep) * layout.panelWidth
    }

    func height(for detent: Detent, in heights: SheetLayout.Heights) -> CGFloat {
        switch detent {
        case .compact: heights.compact
        case .half: heights.half
        case .full: heights.full
        }
    }

    /// 写真とタイトルの部分の高さ。
    func headerHeight(_ layout: SheetLayout) -> CGFloat {
        let expanded = closeBarHeight * layout.fullProgress + layout.expandedImageHeight + 24 + 12 + 12 + 40
        return lerp(layout.heights.compact, expanded, layout.progress)
    }

    /// 段階ごとの高さ。全開は上のセーフエリアの下まで(ステータスバー側にはみ出さない)。
    /// ハーフは「写真と日付だけ」の高さにする(メモなどの中身は全開で出す)。
    private func detentHeights(in size: CGSize) -> SheetLayout.Heights {
        let fullHeight = size.height - DeviceMetrics.windowSafeAreaTop
        let halfImageWidth = size.width - expandedMargin * 2 - headerPadding * 2
        let halfCap = halfImageCap(fullHeight: fullHeight)
        let halfOwnImage = imageHeight(aspectRatio: headerAspectRatio, width: halfImageWidth, cap: halfCap)
        let halfNextImage = neighborImageHeight(width: halfImageWidth, cap: halfCap) ?? halfOwnImage
        let halfImage = lerp(halfOwnImage, halfNextImage, swipeReveal)
        let halfHeight = min(halfImage + 24 + 12 + 12 + 40, fullHeight - 120)
        return SheetLayout.Heights(compact: config.smallestDetentHeight, half: halfHeight, full: fullHeight)
    }

    private func halfImageCap(fullHeight: CGFloat) -> CGFloat {
        max(config.expandedImageHeight, fullHeight * 0.42)
    }

    /// 写真の縦横比どおりの高さ。設定の高さより低くはせず、`cap` を超えない。
    private func imageHeight(aspectRatio: CGFloat, width: CGFloat, cap: CGFloat) -> CGFloat {
        min(max(width / max(aspectRatio, 0.2), config.expandedImageHeight), cap)
    }

    /// スワイプ中なら、スワイプ先の写真の高さ。スワイプしていなければ nil。
    private func neighborImageHeight(width: CGFloat, cap: CGFloat) -> CGFloat? {
        guard pageOffset != 0, let snap = neighbor?(peekStep) else { return nil }
        return imageHeight(aspectRatio: snap.aspectRatio, width: width, cap: cap)
    }
}
