# 0003: パネルと追加ボタンを Liquid Glass にする

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-02

## 決定

- パネルと追加ボタンは `glassEffect` で描く。パネルはヘッダー色（黄）を弱い tint として乗せる。追加ボタンは色なしのガラス。
- × ボタンは自前の丸ではなく、純正の `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)`。

## 背景

対象 OS は iOS 26 以降（`Project.swift`）。自前の丸＋`.thinMaterial` は、システムのボタンと太さ・影・押したときの反応が違い、「カスタムすぎる」と判断した。

## 判明した制約

- ガラスは `opacity` で薄くしても円が残る場面があった。そこで、追加ボタンは `GlassEffectContainer` の外に出し、`opacity` と縮小で消す形にした。
- `GlassEffectContainer` の間隔を大きくすると、バナーと追加ボタンが液状につながる。別々に見せるには使わないか、間隔を小さくする。
- `Button(role: .close)` は、シートの外では「閉じる」の文字付きボタンになるため採用しなかった。

## 参考

- [CustomSheetView.swift](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift#L271-L366)
