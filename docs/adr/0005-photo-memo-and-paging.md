# 0005: 写真のメモと、全開時の左右スワイプで前後へ移る

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-03

## 決定

- 写真にメモ（`TripPhoto.memo`、文字列）を持たせ、パネルの中身（写真の下）に出す。直接編集できる。
- 全開のとき、左右にスワイプすると前後の写真へ移る。撮影順（`takenAt`）で並べ、端では進まない。
- コンパクト・ハーフでは左右スワイプで移らない（地図の操作や縦ドラッグと紛れやすいため）。

## 動き（Tinder 風）

- 指に追従して横へ動き、動いた量だけ傾く。
- 110pt 以上動かすか、勢いよく払うと、飛んでいき、次の写真が入る。足りなければ戻る。
- 動くのは**写真だけ**。日時・メモは動かさず、飛んで入れ替わった時点で切り替える（2026-10-03 変更。最初は文字ごと動かしていた）。
- 文字（日時・メモ）は動かさない。スワイプ量に応じて手前の文字が薄くなり、スワイプ先の文字が同じ位置に濃くなって現れる（スワイプ中から見える）。
- スワイプ中は、動く向きの隣の**写真を後ろに先読み**して見せる。隣の写真の縦横比から高さを先に求め、文字の位置もその高さへ寄せる。払ったあと、後ろで見えていた写真がそのまま手前になるので、点滅しない。

## 比較

| 案 | 内容 | 採否 |
|---|---|---|
| A. 指を離してから次を入れる | 実装は軽い | 不採用（飛んだあとに空白が出る） |
| B. 隣を先に描き、後ろに置く | 手前と同じ見た目を2枚持つ | 採用 |
| C. `TabView` のページング | 標準の動き | 不採用（傾き・飛ばす動きを出せない） |

## 割り切り

隣の写真の高さは `neighbor` が返す縦横比から計算する。呼び出し側は、隣の `PageSnapshot` を毎フレーム作れる程度に軽く保つこと。

## 参考

- [CustomSheetView.swift（先読み）](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift#L368-L407)
- [CustomSheetView.swift（飛ばす動き）](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift#L408-L440)
- [TripPhoto.swift](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Models/TripPhoto.swift#L14)
