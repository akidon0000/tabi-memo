# 0010: 全開の左右スワイプは、写真と文字をページごと滑らせる

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-05

## 決定

全開のときの左右スワイプでは、写真・日時・メモを1枚のページとして一緒に横へ滑らせる。隣のページは横から入ってくる。写真は傾けず、薄くもしない。

ハーフは [ADR 0005](0005-photo-memo-and-paging.md) のまま(写真だけが傾いて飛び、文字は入れ替わる)。ただし、写真を薄くする演出はハーフでもやめた(FB-9)。

## 背景

実機テストの FB で、全開ではメモと写真が同時に動いてほしい(FB-7)、写真を薄くしなくてよい(FB-9)と出た。ADR 0005 では、文字を動かさず写真だけを飛ばす形にしていた。全開は写真の下にメモが長く続く読む画面なので、ページをめくる動きのほうが合う。

## 比較

| 案 | 内容 | 採否 |
|---|---|---|
| A. 全段階でページごと滑らせる | ハーフも同じ動き | 不採用(ハーフは地図と一緒に見る段階で、写真だけ飛ぶ軽い動きが合っている) |
| B. 全開だけページごと滑らせる | 段階で動きを変える | 採用 |
| C. いまのまま | ADR 0005 | 不採用(FB と合わない) |

## 割り切り・注意

- 隣のページは、スクロールする前の位置(いちばん上)で見せる。入れ替わると一番上から表示するため。
- 隣のページの写真は、ヘッダーの層に置く。スクロールの層の下に置くと、白い背景越しに薄く見えた。
- 隣の写真の画像は、描画のたびに作り直さず、写真ごとに展開済みの画像を使い回す。作り直すと、アニメーション中に SwiftUI がクロスフェードして薄く見える。

## 参考

- 要件: [requirements/0002](../requirements/0002-map-and-panel-feedback.md)
- [CustomSheetView+Header.swift(隣のページ)](https://github.com/akidon0000/tabi-memo/blob/7d4dc6a6e385b495b6367c1dd1c008decdce35fe/TabiMemo/Sources/Shared/Components/CustomSheet/CustomSheetView%2BHeader.swift)
- [Photo+Image.swift(画像のキャッシュ)](https://github.com/akidon0000/tabi-memo/blob/7d4dc6a6e385b495b6367c1dd1c008decdce35fe/TabiMemo/Sources/Shared/Extensions/Photo%2BImage.swift)
