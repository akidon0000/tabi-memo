import SharedUI
import SwiftUI

extension CustomSheetView {
    /// 写真とタイトル(スクロールで流れる部分)と、その上に固定する行(ドラッグバーと閉じるボタン)。
    func header(_ layout: SheetLayout, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            scrollingHeader(layout, height: height)
                .contentShape(Rectangle())
                // 全開では下の ScrollView にタッチを通す(スクロール・縦ドラッグの競合を避ける)。
                .allowsHitTesting(detent != .full)
                .gesture(dragGesture(heights: layout.heights))
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($isPressing) { _, state, _ in state = true }
                )

            fixedRow(layout)
        }
        .frame(height: height, alignment: .top)
    }

    /// 写真とタイトル。全開ではスクロール量だけ上へ流す(中身と一緒に動く)。
    /// 写真そのものは自分の高さのまま。文字はスワイプ先の高さに合わせた位置へ先に寄る。
    private func scrollingHeader(_ layout: SheetLayout, height: CGFloat) -> some View {
        let progress = layout.progress
        let imageHeight = lerp(compactImageSize, layout.ownImageHeight, progress)
        let textImageHeight = lerp(compactImageSize, layout.expandedImageHeight, progress)
        // 写真は×ボタンの行の下に置く(×は全開のときだけなので、行も全開に向けて確保する)。
        let barHeight = closeBarHeight * layout.fullProgress
        let expandedTextTop = barHeight + textImageHeight + 12
        // ハーフの左右スワイプ中は、動いた量に応じて文字を薄くする。入れ替わったあと、次の文字が濃くなって出る。
        // 全開では文字も写真と一緒に動くので、薄くしない。
        let textFade = (slidesPages ? 1 : 1 - swipeReveal) * textReveal
        let textOffset = slidesPages ? pageOffset : 0
        // 畳み側と展開側のタイトルを重ならないようにクロスフェードする。
        let compactOpacity = max(1 - progress * 4, 0)
        let expandedOpacity = max(progress * 2 - 1, 0) * textFade

        return ZStack(alignment: .topLeading) {
            headerPhoto(layout, height: imageHeight)
                .padding(.top, barHeight)

            titleBlock(title: title, caption: caption, fontSize: 16)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .opacity(compactOpacity * textFade)

            titleBlock(title: title, caption: caption, fontSize: 24)
                .padding(.top, expandedTextTop)
                .offset(x: textOffset)
                .opacity(expandedOpacity)

            if slidesPages {
                slidingNeighbor(layout, barHeight: barHeight)
            } else {
                neighborTitles(expandedTop: expandedTextTop, progress: progress, compactOpacity: compactOpacity)
            }

            // 編集・削除ボタン(写真の右下)。
            if onEdit != nil {
                actionButtons()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .padding(.top, actionButtonsTop(barHeight: barHeight, imageHeight: imageHeight))
                    .offset(x: textOffset)
                    .opacity(expandedOpacity)
                    .allowsHitTesting(progress > 0.9 && detent != .full)
            }
        }
        .padding(.horizontal, headerPadding)
        .padding(.top, lerp((config.smallestDetentHeight - compactImageSize) / 2, 24, progress))
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .offset(y: -scrollOffset * layout.fullProgress)
    }

    /// 写真。角は、パネルの角に同心(パネルの半径 - 写真までの余白)。全開ではパネルの角が消えるので 20 に寄せる。
    private func headerPhoto(_ layout: SheetLayout, height: CGFloat) -> some View {
        let progress = layout.progress
        let inset = lerp((config.smallestDetentHeight - compactImageSize) / 2, headerPadding, progress)
        let concentricRadius = max(panelRadius(progress: progress) - inset, 0)
        let radius = lerp(concentricRadius, 20, layout.fullProgress)
        return headerImage
            .resizable()
            .scaledToFill()
            .frame(width: lerp(compactImageSize, layout.expandedImageWidth, progress), height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            // 左右スワイプで動くのは写真だけ。文字は動かさず、移動が終わってから切り替わる。
            .modifier(PageCard(offset: pageOffset, scale: pageScale, rotates: !slidesPages))
            .onTapGesture { if progress > 0.5 { onImageTap?() } }
    }

    /// スワイプ先の日時。スワイプ中から現れ、手前の日時と入れ替わる。
    @ViewBuilder
    private func neighborTitles(expandedTop: CGFloat, progress: CGFloat, compactOpacity: CGFloat) -> some View {
        if pageOffset != 0, let snap = neighbor?(peekStep) {
            Text(snap.title)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .padding(.top, expandedTop)
                .opacity(max(progress * 2 - 1, 0) * swipeReveal)
            Text(snap.title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .frame(height: compactImageSize, alignment: .center)
                .padding(.leading, compactImageSize + 12)
                .opacity(compactOpacity * swipeReveal)
        }
    }

    /// 全開のスライドで、隣のページの写真と日時。手前の写真と同じ層・同じ描き方で隣に並べ、一緒に滑らせる。
    /// スクロールする前の位置で見せる(入れ替わると一番上から表示するため)。
    @ViewBuilder
    private func slidingNeighbor(_ layout: SheetLayout, barHeight: CGFloat) -> some View {
        if pageOffset != 0, let snap = neighbor?(peekStep) {
            ZStack(alignment: .topLeading) {
                snap.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.expandedImageWidth, height: layout.nextImageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, barHeight)
                titleBlock(title: snap.title, caption: snap.caption, fontSize: 24)
                    .padding(.top, barHeight + layout.nextImageHeight + 12)
            }
            .offset(x: neighborOffset(layout), y: scrollOffset)
            .allowsHitTesting(false)
        }
    }

    /// 上に固定する行: ドラッグバー、閉じるボタン。専用の背景は敷かず、パネル全体の背景(全開で白)と同じ色にする。
    /// 写真はこの下を、切り取られずに流れる。
    private func fixedRow(_ layout: SheetLayout) -> some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(height: 40)
                .contentShape(Rectangle())
                .onTapGesture { advanceDetent() }
                .gesture(dragGesture(heights: layout.heights))
                .frame(maxHeight: .infinity, alignment: .top)

            Capsule()
                .fill(.secondary.opacity(0.6))
                .frame(width: 36, height: 5)
                // 全開に向かうほど、右の×と同じ横一列(中心をそろえる)へ寄せる。
                .padding(.top, lerp(6, closeRowTop + closeButtonSize / 2 - 2.5, layout.fullProgress))
                // 全開で「下にスワイプできる」ことを知らせるときに、下へ揺らす。
                .offset(y: barNudge)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity, alignment: .top)

            // 全開では、地図画面の「…」が消えて、同じ右上の位置に×が出る。
            closeButton
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, headerPadding)
                .padding(.top, closeRowTop)
                // 全開のときだけ表示する(ハーフでは出さない)。
                .opacity(layout.fullProgress)
                .allowsHitTesting(layout.fullProgress > 0.9)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
