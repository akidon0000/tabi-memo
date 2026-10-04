import SwiftUI

extension CustomSheetView {
    /// ペン(編集)とゴミ箱(取り除く)を1つにまとめた、ガラスの楕円(カプセル)。
    func actionButtons() -> some View {
        HStack(spacing: 0) {
            Button { onEdit?() } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 48, height: actionButtonHeight)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("編集")
            Divider()
                .frame(height: 20)
            Button { onDelete?() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 48, height: actionButtonHeight)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("取り除く")
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    /// ボタンを置く、スクロール内容の上端からの位置(写真の右下)。
    func actionButtonsTop(barHeight: CGFloat, imageHeight: CGFloat) -> CGFloat {
        barHeight + imageHeight - 8 - actionButtonHeight
    }

    /// 後ろに見せる前後の写真。写真だけを先読みする。文字(日時・メモ)は、飛んで入れ替わったあとに切り替わる。
    func peekCard(_ snap: PageSnapshot, layout: SheetLayout, topPad: CGFloat) -> some View {
        // 文字は動かさないので、後ろの写真も手前と同じ大きさにそろえる(縦横比が違えば切り抜く)。
        let imageHeight = lerp(compactImageSize, layout.nextImageHeight, layout.progress)
        let imageWidth = lerp(compactImageSize, layout.expandedImageWidth, layout.progress)
        return snap.image
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: lerp(24, 20, layout.progress)))
            .padding(.horizontal, headerPadding)
            .padding(.top, topPad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .scaleEffect(0.94 + 0.06 * swipeReveal, anchor: .top)
            .opacity(0.4 + 0.6 * swipeReveal)
            .allowsHitTesting(false)
    }

    /// iOS 26 純正のガラスの丸ボタン(.glass + .circle)。サイズと押下の反応はシステムに任せる。
    var closeButton: some View {
        Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                detent = .compact
            }
        } label: {
            // 全開では「×」ではなく、下へ畳む向きの「∨」にする。
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .frame(width: closeButtonSize, height: closeButtonSize)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("閉じる")
    }

    func titleBlock(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .lineLimit(1)
            if !caption.isEmpty {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    func addButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: addButtonSize, height: addButtonSize)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
    }
}
