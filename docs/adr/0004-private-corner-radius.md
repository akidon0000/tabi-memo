# 0004: 画面角の半径に非公開キーを使う

- 状態: 暫定
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-02

## 決定

ハーフのパネルと写真の角丸を端末の画面角に同心にするため、`UIScreen.value(forKey: "_displayCornerRadius")` を読む。取れなければ 55pt を使う。

## 背景

画面角の半径を取る公開 API が（iOS 26 の `ConcentricRectangle` を除き）無い。手元の確認を先に進めるため、非公開キーで先に作った。

## リスク

- **App Store 審査**: 非公開 API の利用として指摘される恐れがある。出す前に置き換える。
- 機種ごとの半径は未確認。iPhone 18 Pro 以外（角の小さい機種）は見ていない。

## 置き換えの方針

`ConcentricRectangle`（iOS 26）に替える。コンパクト（カプセル）からハーフ（同心）へ、角の半径を補間している部分を作り直す必要がある。

## 見直しのタイミング

TestFlight / App Store に出す前。必須。

## 参考

- [CustomSheetView.swift](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift#L249-L270)
- [CustomSheetView.swift（deviceCornerRadius）](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift#L516-L525)
